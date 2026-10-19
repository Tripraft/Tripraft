# Purpose: Exports registered Flask paths and explicit admin/partner schemas using a migrated disposable database.
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
    from app.partners.schemas import AgreementAcknowledgment, PartnerAgreementDocument, PartnerAgreementStatus
    from app.partners.package_schemas import (CreateTourDraft, SaveTourDraft, DuplicateTourDraft, TourDraftContent,
                                             PackageSummary, PackageDraft, PackageList)
    schemas = {
        'User': {'type': 'object', 'required': ['id', 'email', 'is_admin'], 'properties': {
            'id': {'type': 'string', 'format': 'uuid'}, 'email': {'type': 'string'},
            'display_name': {'type': ['string', 'null']}, 'is_admin': {'type': 'boolean'},
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
        'AuditResponse': envelope(ref('AuditData')),
    }
    for model in (PartnerRegister, PartnerLogin, ApplicationUpdate, ApplicationSubmit, ReviewDecision,
                  AgreementAcknowledgment, PartnerAgreementDocument, PartnerAgreementStatus,
                  CreateTourDraft, SaveTourDraft, DuplicateTourDraft, TourDraftContent, PackageSummary, PackageDraft, PackageList):
        schema = model.model_json_schema(ref_template='#/components/schemas/{model}')
        schemas.update(schema.pop('$defs', {}))
        schemas[model.__name__] = schema
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
                          'staff_login': 'PartnerLogin', 'create_package_draft': 'CreateTourDraft', 'duplicate_package_draft': 'DuplicateTourDraft'}
                if action == 'package_draft' and method == 'PATCH':
                    inputs[action] = 'SaveTourDraft'
                if action in inputs:
                    operation['requestBody'] = {'required': True, 'content': {'application/json': {'schema': ref(inputs[action])}}}
                if action in ('register', 'login', 'me', 'update_application', 'submit_application', 'acknowledge_agreement'):
                    output = ref('PartnerSnapshotResponse')
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
                elif action in ('create_package_draft', 'duplicate_package_draft', 'package_draft'):
                    output = envelope(ref('PackageDraft'))
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
                    }}
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
            paths.setdefault(route, {})[method.lower()] = operation
    return {'openapi': '3.1.0', 'info': {'title': 'TripRaft API', 'version': '2.0.0',
            'description': 'Route inventory with explicit admin and partner operations schemas. Unspecified payloads remain unknown.'},
            'paths': paths, 'components': {'schemas': schemas,
            'securitySchemes': {'cookieAuth': {'type': 'apiKey', 'in': 'cookie', 'name': 'access_token'},
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
