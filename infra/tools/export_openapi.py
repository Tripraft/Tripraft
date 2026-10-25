# Purpose: Builds services/api/openapi.json from Flask routes and explicit admin/partner schemas using a migrated temporary SQLite database; unspecified response payloads remain unknown.
"""Export registered Flask routes without opening or modifying the user's database.

Known operations have explicit response schemas. Other response payloads remain
unknown until their contracts are specified; route discovery is not schema inference.
"""
import json
import os
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / 'services/api'
sys.path.insert(0, str(API))


def ref(name):
    return {'$ref': f'#/components/schemas/{name}'}


def response(schema):
    return {'description': 'Response', 'content': {'application/json': {'schema': schema}}}


def envelope(data):
    return {'type': 'object', 'required': ['success', 'data'], 'properties': {
        'success': {'type': 'boolean'}, 'data': data, 'message': {'type': 'string'},
    }}


def build(application):
    from app.partners.schemas import ApplicationSubmit, ApplicationUpdate, PartnerLogin, PartnerRegister, ReviewDecision
    from app.partners.schemas import AgentAgreementSign, AgentSignatureReceipt, AgreementAcknowledgment, PartnerAgreementDocument, PartnerAgreementStatus
    from app.partners.package_schemas import (CreateTourDraft, SaveTourDraft, DuplicateTourDraft, TourDraftContent,
                                             PackageSummary, PackageDraft, PackageList, SubmitTourPackage,
                                             PackageReviewDecision, UploadPackageImage, PackageReviewList)
    schemas = {
        'User': {'type': 'object', 'required': ['id', 'email', 'is_admin'], 'properties': {
            'id': {'type': 'string', 'format': 'uuid'}, 'email': {'type': 'string'},
            'display_name': {'type': ['string', 'null']}, 'is_admin': {'type': 'boolean'},
            'personal_display_currency': {'type': ['string', 'null'], 'pattern': '^[A-Z]{3}$'},
        }},
        'Health': {'type': 'object', 'required': ['status', 'timestamp'], 'properties': {
            'status': {'type': 'string'}, 'timestamp': {'type': 'string'},
            'service': {'type': 'string'}, 'version': {'type': 'string'},
            'checks': {'type': 'object', 'additionalProperties': {'type': 'object', 'required': ['status'], 'properties': {
                'status': {'type': 'string'}, 'note': {'type': 'string'}, 'error': {'type': 'string'},
            }}},
        }},
        'AuditRecord': {'type': 'object', 'properties': {
            'id': {'type': ['integer', 'string']}, 'created_at': {'type': 'string'},
            'entity_type': {'type': 'string'}, 'action': {'type': 'string'}, 'ingested_by': {'type': ['string', 'null']},
        }},
        'AuditData': {'type': 'object', 'required': ['total', 'logs'], 'properties': {
            'total': {'type': 'integer'}, 'logs': {'type': 'array', 'items': ref('AuditRecord')},
        }},
        'MeResponse': envelope({'type': 'object', 'required': ['user'], 'properties': {'user': ref('User')}}),
        'ExpenseFriend': {'type': 'object', 'required': ['id', 'email', 'label', 'is_registered'], 'properties': {
            'id': {'type': 'string', 'format': 'uuid'}, 'email': {'type': 'string', 'format': 'email'},
            'nickname': {'type': ['string', 'null'], 'maxLength': 100},
            'display_name': {'type': ['string', 'null']}, 'label': {'type': 'string'},
            'is_registered': {'type': 'boolean'}, 'user_id': {'type': ['string', 'null'], 'format': 'uuid'},
        }},
        'SaveExpenseFriend': {'type': 'object', 'required': ['email'], 'additionalProperties': False, 'properties': {
            'email': {'type': 'string', 'format': 'email'},
            'nickname': {'type': ['string', 'null'], 'maxLength': 100},
        }},
        'ExpenseFriendsResponse': envelope({'type': 'object', 'required': ['friends', 'total', 'has_more', 'limit', 'offset'], 'properties': {
            'friends': {'type': 'array', 'items': ref('ExpenseFriend')}, 'total': {'type': 'integer'},
            'has_more': {'type': 'boolean'}, 'limit': {'type': 'integer'}, 'offset': {'type': 'integer'},
        }}),
        'ExpenseFriendResponse': envelope({'type': 'object', 'required': ['friend'], 'properties': {'friend': ref('ExpenseFriend')}}),
        'AuditResponse': envelope(ref('AuditData')),
    }
    for model in (PartnerRegister, PartnerLogin, ApplicationUpdate, ApplicationSubmit, ReviewDecision,
                  AgreementAcknowledgment, PartnerAgreementDocument, PartnerAgreementStatus,
                  AgentAgreementSign, AgentSignatureReceipt,
                  CreateTourDraft, SaveTourDraft, DuplicateTourDraft, TourDraftContent, PackageSummary, PackageDraft, PackageList,
                  SubmitTourPackage, PackageReviewDecision, UploadPackageImage, PackageReviewList):
        schema = model.model_json_schema(ref_template='#/components/schemas/{model}')
        schemas.update(schema.pop('$defs', {}))
        schemas[model.__name__] = schema
    from app.employees import schemas as employee_schemas
    for name in ('EmployeeCreate', 'EmployeeChange', 'RequestCreate', 'RequestDecision', 'EmployeeLogin',
                 'InviteAccept', 'EmployeeRecord', 'AccessRequestRecord', 'AccessEventRecord',
                 'ProvisioningJobRecord', 'EmployeeIdentity'):
        schema = getattr(employee_schemas, name).model_json_schema(ref_template='#/components/schemas/{model}')
        schemas.update(schema.pop('$defs', {}))
        schemas[name] = schema
    status_values = ['DRAFT_APPLICATION', 'UNDER_REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'SUSPENDED', 'REJECTED']
    application_fields = {name: {'type': 'string'} for name in (
        'business_name', 'representative_name', 'contact_email', 'phone', 'country_code', 'website',
    )}
    application_fields.update({
        'id': {'type': 'string', 'format': 'uuid'}, 'version': {'type': 'integer', 'minimum': 1},
        'status': {'type': 'string', 'enum': status_values},
        'is_demo': {'type': 'boolean'},
        'business_type': {'type': 'string', 'enum': ['tour_operator', 'travel_agency']},
        'operating_regions': {'type': 'array', 'items': {'type': 'string'}},
        'review_reason': {'type': ['string', 'null']},
        'submitted_at': {'type': ['string', 'null'], 'format': 'date-time'},
        'updated_at': {'type': 'string', 'format': 'date-time'},
    })
    schemas['PartnerApplication'] = {'type': 'object', 'required': list(application_fields), 'properties': application_fields}
    schemas['PartnerSnapshot'] = {'type': 'object', 'required': ['user', 'application', 'agreement', 'capabilities'], 'properties': {
        'user': {'type': 'object', 'required': ['id', 'email', 'display_name', 'email_verified'], 'properties': {
            'id': {'type': 'string', 'format': 'uuid'}, 'email': {'type': 'string'},
            'display_name': {'type': ['string', 'null']}, 'email_verified': {'type': 'boolean'},
        }},
        'application': ref('PartnerApplication'), 'verification_email_sent': {'type': 'boolean'},
        'agreement': ref('PartnerAgreementStatus'),
        'capabilities': {'type': 'object', 'required': ['can_edit_application', 'can_submit_application', 'can_view_dashboard', 'can_manage_packages'], 'properties': {
            name: {'type': 'boolean'} for name in ('can_edit_application', 'can_submit_application', 'can_view_dashboard', 'can_manage_packages')
        }},
    }}
    schemas['PartnerSnapshotResponse'] = envelope(ref('PartnerSnapshot'))
    schemas['PartnerReviewApplication'] = {'allOf': [ref('PartnerApplication'), {'type': 'object', 'required': ['is_own_application', 'agreement'], 'properties': {'is_own_application': {'type': 'boolean'}, 'agreement': ref('PartnerAgreementStatus')}}]}
    schemas['PartnerReviewListResponse'] = envelope({'type': 'object', 'required': ['applications', 'total'], 'properties': {
        'applications': {'type': 'array', 'items': ref('PartnerReviewApplication')}, 'total': {'type': 'integer'},
    }})
    schemas['PartnerError'] = {'type': 'object', 'required': ['success', 'error'], 'properties': {
        'success': {'type': 'boolean'}, 'data': {'type': 'null'},
        'error': {'oneOf': [{'type': 'string'}, {'type': 'object', 'required': ['code', 'message'], 'properties': {
            'code': {'type': 'string'}, 'message': {'type': 'string'},
            'details': {'type': 'object', 'additionalProperties': {'type': 'array', 'items': {'type': 'string'}}},
        }}]},
    }}
    paths = {}
    for rule in sorted(application.url_map.iter_rules(), key=lambda r: (r.rule, r.endpoint)):
        if not (rule.rule.startswith('/api/v1/') or rule.rule.startswith('/api/health/')):
            continue
        route = re.sub(r'<(?:[^:>]+:)?([^>]+)>', r'{\1}', rule.rule)
        for method in sorted(rule.methods - {'OPTIONS', 'HEAD'}):
            route_id = re.sub(r'[^a-zA-Z0-9]+', '_', route).strip('_')
            operation = {'operationId': rule.endpoint.replace('.', '_') + '_' + method.lower() + '_' + route_id,
                         'responses': {'default': response({})},
                         'description': 'Registered route. Response payload is unspecified unless an explicit schema is attached.'}
            if rule.arguments:
                operation['parameters'] = [{'name': name, 'in': 'path', 'required': True, 'schema': {
                    'type': 'integer' if rule._converters[name].__class__.__name__ == 'IntegerConverter' else 'string',
                }} for name in sorted(rule.arguments)]
            if route == '/api/v1/auth/me' and method == 'GET':
                operation['responses']['200'] = response(ref('MeResponse'))
                operation['security'] = [{'cookieAuth': []}]
            elif route == '/api/v1/expenses/friends':
                operation['security'] = [{'cookieAuth': []}]
                operation['responses']['200'] = response(ref('ExpenseFriendsResponse' if method == 'GET' else 'ExpenseFriendResponse'))
                if method == 'POST':
                    operation['requestBody'] = {'required': True, 'content': {'application/json': {'schema': ref('SaveExpenseFriend')}}}
                else:
                    operation['parameters'] = [
                        {'name': 'search', 'in': 'query', 'schema': {'type': 'string', 'maxLength': 255}},
                        {'name': 'limit', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100}},
                        {'name': 'offset', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0}},
                    ]
            elif route in {'/api/health/live', '/api/health/ready', '/api/health/'}:
                operation['responses']['200'] = response(ref('Health'))
                if route.endswith('/ready'):
                    operation['responses']['503'] = response(ref('Health'))
            elif route == '/api/v1/admin/audit' and method == 'GET':
                operation['responses']['200'] = response(ref('AuditResponse'))
                operation['security'] = [{'cookieAuth': []}]
                operation['parameters'] = [
                    {'name': name, 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0}}
                    for name in ('limit', 'offset')
                ]
            if rule.endpoint.startswith('partners.'):
                operation['description'] = 'Supplier-only onboarding or internal administrator review. Mutations using cookies require X-CSRF-Token except register/login. Responses are never cached.'
                action = rule.endpoint.split('.')[-1]
                inputs = {'register': 'PartnerRegister', 'login': 'PartnerLogin', 'update_application': 'ApplicationUpdate',
                          'submit_application': 'ApplicationSubmit', 'review_application': 'ReviewDecision',
                          'acknowledge_agreement': 'AgreementAcknowledgment',
                          'sign_agreement': 'AgentAgreementSign',
                          'submit_package_review': 'SubmitTourPackage', 'decide_package_review': 'PackageReviewDecision',
                          'staff_login': 'PartnerLogin', 'create_package_draft': 'CreateTourDraft', 'duplicate_package_draft': 'DuplicateTourDraft'}
                if action == 'package_draft' and method == 'PATCH':
                    inputs[action] = 'SaveTourDraft'
                if action in inputs:
                    operation['requestBody'] = {'required': True, 'content': {'application/json': {'schema': ref(inputs[action])}}}
                if action == 'upload_package_image':
                    operation['requestBody'] = {'required': True, 'content': {'multipart/form-data': {'schema': {
                        'type': 'object', 'required': ['version', 'file', 'caption', 'rights_source', 'rights_attestation'],
                        'additionalProperties': False, 'properties': {
                            'file': {'type': 'string', 'format': 'binary'}, 'version': {'type': 'integer', 'minimum': 1},
                            'caption': {'type': 'string', 'minLength': 2, 'maxLength': 300},
                            'rights_source': {'type': 'string', 'minLength': 5, 'maxLength': 500},
                            'rights_attestation': {'type': 'string', 'enum': ['true']},
                        }}}}}
                if action in ('register', 'login', 'me', 'update_application', 'submit_application', 'acknowledge_agreement', 'sign_agreement'):
                    output = ref('PartnerSnapshotResponse')
                elif action in ('own_signature', 'staff_signature'):
                    output = envelope(ref('AgentSignatureReceipt'))
                elif action == 'own_signature_download':
                    output = ref('AgentSignatureReceipt')
                elif action in ('partner_agreement', 'staff_agreement'):
                    output = envelope(ref('PartnerAgreementDocument'))
                elif action in ('partner_agreement_download', 'staff_agreement_download'):
                    output = {'type': 'string', 'format': 'binary'}
                elif action == 'list_applications':
                    output = ref('PartnerReviewListResponse')
                    operation['parameters'] = [
                        {'name': 'status', 'in': 'query', 'schema': {'type': 'string', 'enum': status_values, 'default': 'UNDER_REVIEW'}},
                        {'name': 'limit', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100, 'default': 25}},
                        {'name': 'offset', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0, 'maximum': 10000, 'default': 0}},
                    ]
                elif action == 'review_application':
                    output = envelope(ref('PartnerApplication'))
                elif action in ('create_package_draft', 'duplicate_package_draft', 'package_draft', 'submit_package_review', 'upload_package_image'):
                    output = envelope(ref('PackageDraft'))
                elif action == 'list_package_reviews':
                    output = envelope(ref('PackageReviewList'))
                elif action == 'decide_package_review':
                    output = envelope({'type': 'object', 'required': ['status', 'version', 'approved_revision'], 'properties': {
                        'status': {'type': 'string'}, 'version': {'type': 'integer'}, 'approved_revision': {'type': ['integer', 'null']},
                    }})
                elif action in ('partner_package_image', 'staff_package_image'):
                    output = {'type': 'string', 'format': 'binary'}
                elif action == 'list_package_drafts':
                    output = envelope(ref('PackageList'))
                    operation['parameters'] = [
                        {'name': 'limit', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100, 'default': 25}},
                        {'name': 'offset', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0, 'maximum': 10000, 'default': 0}},
                    ]
                elif action == 'staff_login':
                    output = envelope({'type': 'object', 'required': ['signed_in'], 'properties': {'signed_in': {'type': 'boolean'}}})
                else:
                    fields = {'refresh': {'refreshed': {'type': 'boolean'}}, 'logout': {'signed_out': {'type': 'boolean'}},
                              'resend_verification': {'message': {'type': 'string'}}}[action]
                    output = envelope({'type': 'object', 'properties': fields})
                operation['responses'] = {('201' if action in ('register', 'create_package_draft', 'duplicate_package_draft') else '200'): response(output)}
                if action in ('partner_agreement_download', 'staff_agreement_download'):
                    operation['responses']['200'] = {'description': 'Authenticated original draft Word attachment; never cached.', 'content': {
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document': {'schema': output},
                        'text/plain': {'schema': {'type': 'string'}, 'description': 'Complete policy text when original Office sources are excluded.'},
                    }}
                if action in ('partner_package_image', 'staff_package_image'):
                    operation['responses']['200'] = {'description': 'Authenticated sanitized JPEG; never cached.', 'content': {'image/jpeg': {'schema': output}}}
                for status in ('401', '403', '409', '422', '429', '503'):
                    operation['responses'][status] = response(ref('PartnerError'))
                if action in ('review_application', 'package_draft', 'duplicate_package_draft'):
                    operation['responses']['404'] = response(ref('PartnerError'))
                if action not in ('register', 'login', 'staff_login'):
                    security = 'cookieAuth' if route.startswith('/api/v1/admin/') else 'partnerRefreshCookieAuth' if action in ('refresh', 'logout') else 'partnerCookieAuth'
                    operation['security'] = [{security: []}]
                    if action == 'logout':
                        operation['security'].append({})
                if method != 'GET' and action not in ('register', 'login', 'staff_login'):
                    operation.setdefault('parameters', []).append({'name': 'X-CSRF-Token', 'in': 'header', 'schema': {'type': 'string'}, 'description': 'Required with cookie authentication.'})
            if rule.endpoint.startswith('employees.'):
                action = rule.endpoint.split('.')[-1]
                operation['description'] = 'Employee control plane. CTO authority is independent of ADMIN_EMAILS. External access changes are queued; no provisioning credentials are exposed.'
                inputs = {'login': 'EmployeeLogin', 'accept_invitation': 'InviteAccept', 'create': 'EmployeeCreate',
                          'change': 'EmployeeChange', 'submit_request': 'RequestCreate', 'resubmit': 'RequestCreate', 'decide': 'RequestDecision'}
                if action in inputs:
                    operation['requestBody'] = {'required': True, 'content': {'application/json': {'schema': ref(inputs[action])}}}
                fields = {
                    'login': {'signed_in': {'type': 'boolean'}}, 'logout': {},
                    'directory': {'employees': {'type': 'array', 'items': ref('EmployeeRecord')}, 'total': {'type': 'integer'}},
                    'create': {'employee': ref('EmployeeRecord'), 'created': {'type': 'boolean'}},
                    'change': {'employee': ref('EmployeeRecord'), 'onboarding_token': {'type': 'string', 'description': 'Returned only after confirmed CTO generation of a single-use portal link; never logged or cached.'}}, 'accept_invitation': {'employee': ref('EmployeeRecord')},
                    'requests': {'requests': {'type': 'array', 'items': ref('AccessRequestRecord')}, 'total': {'type': 'integer'}},
                    'submit_request': {'request': ref('AccessRequestRecord')}, 'resubmit': {'request': ref('AccessRequestRecord')},
                    'decide': {'request': ref('AccessRequestRecord')}, 'retry': {'job': ref('ProvisioningJobRecord')},
                    'history': {'events': {'type': 'array', 'items': ref('AccessEventRecord')},
                                'jobs': {'type': 'array', 'items': ref('ProvisioningJobRecord')},
                                'event_total': {'type': 'integer'}, 'job_total': {'type': 'integer'}},
                }
                output = ref('EmployeeIdentity') if action == 'me' else {'type': 'object', 'required': [key for key in fields[action] if key != 'onboarding_token'], 'properties': fields[action]}
                operation['responses'] = {('201' if action in ('create', 'submit_request') else '200'): response(envelope(output))}
                if action == 'create':
                    operation['responses']['200'] = response(envelope(output))
                for status in ('400', '401', '403', '409', '429'):
                    operation['responses'][status] = response(ref('PartnerError'))
                if action != 'login':
                    operation['security'] = [{'cookieAuth' if action == 'accept_invitation' else 'employeeCookieAuth': []}]
                if method != 'GET':
                    operation.setdefault('parameters', []).append({'name': 'X-CSRF-Token', 'in': 'header', 'schema': {'type': 'string'}, 'description': 'Required for authenticated cookie mutations.'})
                if action in ('directory', 'requests', 'history'):
                    operation.setdefault('parameters', []).extend([
                        {'name': 'limit', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'maximum': 100}},
                        {'name': 'offset', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 0}},
                    ])
            paths.setdefault(route, {})[method.lower()] = operation
    return {'openapi': '3.1.0', 'info': {'title': 'TripRaft API', 'version': '2.0.0',
            'description': 'Route inventory with explicit admin and partner operations schemas. Unspecified payloads remain unknown.'},
            'paths': paths, 'components': {'schemas': schemas,
            'securitySchemes': {'employeeCookieAuth': {'type': 'apiKey', 'in': 'cookie', 'name': 'employee_access_token'},
                                'cookieAuth': {'type': 'apiKey', 'in': 'cookie', 'name': 'access_token'},
                                'partnerCookieAuth': {'type': 'apiKey', 'in': 'cookie', 'name': 'partner_access_token'},
                                'partnerRefreshCookieAuth': {'type': 'apiKey', 'in': 'cookie', 'name': 'partner_refresh_token'}}}}


if __name__ == '__main__':
    os.environ['FLASK_ENV'] = 'development'
    os.environ['SECRET_KEY'] = 'schema-export-disposable-development-secret'
    os.environ['REDIS_URL'] = ''
    scratch = ROOT / 'extra/build/schema-export'
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='schema-', dir=scratch) as temp:
        os.environ['DATABASE_URL'] = 'sqlite:///' + (Path(temp) / 'schema.db').as_posix()
        from alembic import command
        from alembic.config import Config as AlembicConfig
        config = AlembicConfig(str(API / 'alembic.ini'))
        config.set_main_option('script_location', str(API / 'migrations'))
        command.upgrade(config, 'head')
        from app.core.factory import create_app
        spec = build(create_app())
        from app.core.db.connection import engine
        engine.dispose()
    target = API / 'openapi.json'
    target.write_text(json.dumps(spec, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(f'Exported {len(spec["paths"])} paths to {target}')
