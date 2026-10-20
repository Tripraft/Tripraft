// Purpose: Manages vault uploads/downloads and shared pre-trip/packing checklists with assignments, permissions and optimistic toggle rollback.
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import QRCode from 'qrcode';
import {
  UploadCloud,
  FileText,
  Ticket,
  Eye,
  Download,
  Trash2,
  X,
  Plus,
  Check,
  ClipboardCheck,
  QrCode,
} from 'lucide-react';
import { useAuth } from '../../../../context/AuthContext';
import {
  useGroupMembers,
  useGroupChecklist,
  useToggleChecklistItem,
  useVaultFiles,
  useUploadVaultFile,
  useDeleteVaultFile,
  gpKeys,
} from '../../../../hooks/useGroupPlannerQuery';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import apiClient from '../../../../utils/apiClient';
import GlobalConfig from '../../../../config/globalConfig';
import { toArray } from '../../utils/groupPlannerUtils';
import { formatDate, formatFileSize } from '../../utils/formatters';
import { isPlannerDemo } from '../../demo/demoMode';
export default function LogisticsTab({ groupId, showToast, canEdit = true }) {
  const client = useQueryClient(),
    { currentUser } = useAuth();
  const { data: memberRaw } = useGroupMembers(groupId),
    { data: checkRaw, error: checkError, isLoading: checkLoading } = useGroupChecklist(groupId),
    { data: vaultRaw, error: vaultError, isLoading: vaultLoading } = useVaultFiles(groupId);
  const members = toArray(memberRaw, 'members'),
    tasks = toArray(checkRaw, 'checklist'),
    docs = toArray(vaultRaw, 'documents');
  const isAdmin = members.some(
    (m) =>
      String(m.user_id || m.id) === String(currentUser?.uid) &&
      ['creator', 'admin'].includes(m.role),
  );
  const toggleMutation = useToggleChecklistItem(groupId),
    uploadMutation = useUploadVaultFile(groupId),
    deleteMutation = useDeleteVaultFile(groupId);
  const inputRef = useRef(null),
    qrRef = useRef(null);
  const [tab, setTab] = useState('pretrip'),
    [editing, setEditing] = useState(null),
    [saving, setSaving] = useState(false),
    [formError, setFormError] = useState(''),
    [dragging, setDragging] = useState(false),
    [preview, setPreview] = useState(null),
    [previewUrl, setPreviewUrl] = useState(null),
    [previewError, setPreviewError] = useState(''),
    [qrDoc, setQrDoc] = useState(null);
  const visible = tasks.filter((t) =>
      tab === 'packing' ? t.category === 'packing' : t.category !== 'packing',
    ),
    done = visible.filter((t) => t.completed).length,
    percent = visible.length ? Math.round((done / visible.length) * 100) : 0;
  useEffect(() => {
    if (!qrDoc || !qrRef.current) return;
    QRCode.toCanvas(qrRef.current, qrDoc.booking_code, {
      width: 210,
      margin: 2,
      color: { dark: '#102A3A', light: '#FFFFFF' },
    }).catch(() => {});
  }, [qrDoc]);
  useEffect(() => {
    setPreviewUrl(null);
    setPreviewError('');
    if (!preview) return;
    const controller = new AbortController();
    let url;
    apiClient
      .get(`${GlobalConfig.ENDPOINTS.GROUP_PLANNER}/groups/${groupId}/vault/${preview.id}`, {
        responseType: 'blob',
        signal: controller.signal,
      })
      .then((blob) => {
        if (!controller.signal.aborted) {
          url = URL.createObjectURL(blob);
          setPreviewUrl(url);
        }
      })
      .catch((e) => {
        if (!controller.signal.aborted) setPreviewError(e.message);
      });
    return () => {
      controller.abort();
      if (url) URL.revokeObjectURL(url);
    };
  }, [preview, groupId]);
  const refresh = () => {
    client.invalidateQueries({ queryKey: gpKeys.checklist(groupId) });
    client.invalidateQueries({ queryKey: gpKeys.activities(groupId) });
  };
  const upload = async (file) => {
    if (!file || uploadMutation.isPending || !canEdit) return;
    if (file.size > 10 * 1024 * 1024) {
      showToast('Files must be 10 MB or smaller.', 'error');
      return;
    }
    try {
      await uploadMutation.mutateAsync(file);
      client.invalidateQueries({ queryKey: gpKeys.activities(groupId) });
      showToast('Booking uploaded');
    } catch (e) {
      showToast(e.message || 'Upload failed', 'error');
    } finally {
      if (inputRef.current) inputRef.current.value = '';
    }
  };
  const toggle = async (item) => {
    try {
      await toggleMutation.mutateAsync(item.id);
      refresh();
    } catch (e) {
      showToast(e.message || 'Could not update the task', 'error');
    }
  };
  const save = async (event) => {
    event.preventDefault();
    if (saving) return;
    setSaving(true);
    setFormError('');
    const payload = {
      text: editing.text.trim(),
      category: editing.category,
      priority: editing.priority,
      due_date: editing.due_date || null,
      assigned_to_id: editing.assigned_to_id || null,
    };
    try {
      if (editing.id) await groupPlannerApi.updateChecklistItem(groupId, editing.id, payload);
      else
        await groupPlannerApi.addChecklistItem(groupId, payload.text, {
          ...payload,
          due_date: payload.due_date || undefined,
        });
      refresh();
      setEditing(null);
      showToast('Task saved');
    } catch (e) {
      setFormError(e.message || 'Could not save the task');
    } finally {
      setSaving(false);
    }
  };
  const removeTask = async (item) => {
    try {
      await groupPlannerApi.deleteChecklistItem(groupId, item.id);
      refresh();
      showToast('Task removed');
    } catch (e) {
      showToast(e.message || 'Could not remove task', 'error');
    }
  };
  const download = async (doc) => {
    try {
      const blob = await apiClient.get(
        `${GlobalConfig.ENDPOINTS.GROUP_PLANNER}/groups/${groupId}/vault/${doc.id}`,
        { responseType: 'blob' },
      );
      const url = URL.createObjectURL(blob),
        a = document.createElement('a');
      a.href = url;
      a.download = doc.filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (e) {
      showToast(e.message || 'Download failed', 'error');
    }
  };
  return (
    <div className="gp-view">
      <div className="gp-tab-heading">
        <div>
          <span className="gp-eyebrow">PACK LIGHT. PLAN AHEAD.</span>
          <h1>Trip Logistics</h1>
          <p>Your booking documents and shared to-dos, together in one place.</p>
        </div>
      </div>
      <div className="gp-logistics-grid">
        <section className="gp-feature-card gp-vault-section">
          <div className="gp-feature-heading">
            <div className="gp-feature-icon">
              <Ticket size={21} />
            </div>
            <div>
              <h2>The Vault</h2>
              <p>Boarding passes, rail tickets, and hotel confirmations</p>
            </div>
            {canEdit && (
              <button className="gp-section-action" onClick={() => inputRef.current?.click()}>
                <Plus size={14} />
                Upload booking
              </button>
            )}
          </div>
          {canEdit && (
            <div
              className={'gp-booking-dropzone' + (dragging ? ' dragging' : '')}
              onDragOver={(e) => {
                e.preventDefault();
                setDragging(true);
              }}
              onDragLeave={() => setDragging(false)}
              onDrop={(e) => {
                e.preventDefault();
                setDragging(false);
                upload(e.dataTransfer.files[0]);
              }}
            >
              <UploadCloud size={30} />
              <h3>
                {uploadMutation.isPending
                  ? 'Uploading your document...'
                  : 'Drop a ticket PDF or booking screenshot'}
              </h3>
              <p>PDF, JPEG, PNG or WebP · up to 10 MB</p>
              <button
                className="gp-modal-btn-secondary"
                disabled={uploadMutation.isPending}
                onClick={() => inputRef.current?.click()}
              >
                Browse files
              </button>
              <input
                ref={inputRef}
                type="file"
                aria-label="Upload booking file"
                accept=".pdf,.jpg,.jpeg,.png,.webp"
                hidden
                onChange={(e) => upload(e.target.files[0])}
              />
            </div>
          )}
          {vaultLoading ? (
            <p role="status">Loading your bookings...</p>
          ) : vaultError ? (
            <p role="alert">{vaultError.message}</p>
          ) : docs.length === 0 ? (
            <div className="gp-empty-agenda">
              <FileText size={25} />
              <p>Your group's documents will appear here.</p>
            </div>
          ) : (
            <div className="gp-booking-list">
              {docs.map((doc) => (
                <article className="gp-booking-ticket" key={doc.id}>
                  <div className="gp-ticket-mark">
                    <Ticket size={23} />
                  </div>
                  <div className="gp-ticket-information">
                    <span className="gp-eyebrow">
                      {doc.mime_type?.includes('pdf') ? 'PDF BOOKING' : 'BOOKING IMAGE'}
                    </span>
                    <h3>{doc.title || doc.filename}</h3>
                    <p>
                      {doc.uploaded_by_name || 'Member'} · {formatFileSize(doc.file_size)}
                      {doc.visit_date ? ' · ' + formatDate(doc.visit_date) : ''}
                    </p>
                    {doc.booking_code && (
                      <span className="gp-booking-code">{doc.booking_code}</span>
                    )}
                    <div className="gp-ticket-actions">
                      <button onClick={() => setPreview(doc)}>
                        <Eye size={13} />
                        Preview
                      </button>
                      <button onClick={() => download(doc)}>
                        <Download size={13} />
                        Download
                      </button>
                      {doc.booking_code && (
                        <button onClick={() => setQrDoc(doc)}>
                          <QrCode size={13} />
                          Show QR
                        </button>
                      )}
                      {canEdit &&
                        (isAdmin || String(doc.uploaded_by) === String(currentUser?.uid)) && (
                          <button
                            disabled={deleteMutation.isPending}
                            aria-label={'Remove ' + doc.filename}
                            onClick={async () => {
                              try {
                                await deleteMutation.mutateAsync(doc.id);
                                showToast('File removed');
                              } catch (e) {
                                showToast(e.message || 'Could not remove file', 'error');
                              }
                            }}
                          >
                            <Trash2 size={13} />
                          </button>
                        )}
                    </div>
                  </div>
                </article>
              ))}
            </div>
          )}
        </section>
        <section className="gp-feature-card">
          <div className="gp-feature-heading">
            <div
              className="gp-progress-ring"
              style={{ background: `conic-gradient(#087ea4 ${percent}%,#e6f4f9 0)` }}
            >
              <span>{percent}%</span>
            </div>
            <div>
              <h2>Group Checklists</h2>
              <p>
                {done} of {visible.length} tasks completed
              </p>
            </div>
          </div>
          <div className="gp-filter-pills gp-checklist-tabs">
            <button className={tab === 'pretrip' ? 'active' : ''} onClick={() => setTab('pretrip')}>
              Pre-Trip
            </button>
            <button className={tab === 'packing' ? 'active' : ''} onClick={() => setTab('packing')}>
              Packing List
            </button>
          </div>
          {checkLoading ? (
            <p role="status">Loading checklist...</p>
          ) : checkError ? (
            <p role="alert">{checkError.message}</p>
          ) : visible.length === 0 ? (
            <div className="gp-empty-agenda">
              <ClipboardCheck size={25} />
              <p>No tasks in this list yet.</p>
            </div>
          ) : (
            <div className="gp-task-list">
              {visible.map((item) => (
                <div className={'gp-task-row' + (item.completed ? ' done' : '')} key={item.id}>
                  <input
                    type="checkbox"
                    aria-label={'Complete ' + item.item}
                    checked={!!item.completed}
                    disabled={!canEdit || toggleMutation.isPending}
                    onChange={() => toggle(item)}
                  />
                  <div>
                    <button
                      disabled={!canEdit}
                      onClick={() => {
                        setFormError('');
                        setEditing({
                          ...item,
                          text: item.item || item.text,
                          due_date: item.due_date?.slice(0, 10) || '',
                        });
                      }}
                    >
                      {item.item || item.text}
                    </button>
                    <p>
                      {item.assigned_to_name || item.author_name || 'Anyone'}
                      {item.due_date ? ' · Due ' + formatDate(item.due_date) : ''}
                      <span className={'gp-task-priority ' + item.priority}>{item.priority}</span>
                    </p>
                  </div>
                  {canEdit && (
                    <button
                      className="gp-task-delete"
                      aria-label={'Remove task ' + item.item}
                      onClick={() => removeTask(item)}
                    >
                      <Trash2 size={12} />
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
          {canEdit && (
            <button
              className="gp-open-workspace"
              onClick={() => {
                setFormError('');
                setEditing({
                  text: '',
                  category: tab,
                  priority: 'medium',
                  due_date: '',
                  assigned_to_id: '',
                });
              }}
            >
              <Plus size={14} />
              Add Task
            </button>
          )}
        </section>
      </div>
      {editing && (
        <div className="gp-modal-overlay" onClick={() => !saving && setEditing(null)}>
          <form
            className="gp-modal"
            role="dialog"
            aria-modal="true"
            aria-label="Checklist Task"
            onSubmit={save}
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="gp-modal-title">{editing.id ? 'Edit Task' : 'Add Task'}</h2>
            <label className="gp-field">
              Task
              <input
                className="gp-modal-input"
                required
                maxLength={500}
                value={editing.text}
                onChange={(e) => setEditing({ ...editing, text: e.target.value })}
              />
            </label>
            <label className="gp-field">
              List
              <select
                className="gp-modal-input"
                value={editing.category || 'pretrip'}
                onChange={(e) => setEditing({ ...editing, category: e.target.value })}
              >
                <option value="pretrip">Pre-Trip</option>
                <option value="packing">Packing List</option>
              </select>
            </label>
            <label className="gp-field">
              Assign to
              <select
                className="gp-modal-input"
                value={editing.assigned_to_id || ''}
                onChange={(e) => setEditing({ ...editing, assigned_to_id: e.target.value })}
              >
                <option value="">Anyone</option>
                {members.map((m) => (
                  <option key={m.user_id || m.id} value={m.user_id || m.id}>
                    {m.display_name || m.email}
                  </option>
                ))}
              </select>
            </label>
            <div className="gp-form-columns">
              <label className="gp-field">
                Priority
                <select
                  className="gp-modal-input"
                  value={editing.priority}
                  onChange={(e) => setEditing({ ...editing, priority: e.target.value })}
                >
                  {['low', 'medium', 'high'].map((p) => (
                    <option key={p}>{p}</option>
                  ))}
                </select>
              </label>
              <label className="gp-field">
                Due date
                <input
                  type="date"
                  className="gp-modal-input"
                  value={editing.due_date}
                  onChange={(e) => setEditing({ ...editing, due_date: e.target.value })}
                />
              </label>
            </div>
            {formError && <p role="alert">{formError}</p>}
            <div className="gp-modal-actions">
              <button className="gp-modal-btn-primary" disabled={saving}>
                Save Task
              </button>
              <button
                className="gp-modal-btn-secondary"
                type="button"
                disabled={saving}
                onClick={() => setEditing(null)}
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}
      {preview && (
        <div className="gp-modal-overlay" onClick={() => setPreview(null)}>
          <div
            className="gp-doc-preview"
            role="dialog"
            aria-modal="true"
            aria-label="Booking Preview"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="gp-doc-preview-header">
              <h2>{preview.title || preview.filename}</h2>
              <button
                className="gp-icon-button"
                aria-label="Close booking preview"
                onClick={() => setPreview(null)}
              >
                <X size={17} />
              </button>
            </div>
            <div className="gp-doc-preview-body">
              {previewError ? (
                <p role="alert">{previewError}</p>
              ) : !previewUrl ? (
                <p role="status">Loading document...</p>
              ) : preview.mime_type?.includes('pdf') ? (
                <iframe
                  src={previewUrl}
                  title={preview.filename}
                  className="gp-doc-preview-iframe"
                />
              ) : (
                <img src={previewUrl} alt={preview.filename} className="gp-doc-preview-img" />
              )}
            </div>
          </div>
        </div>
      )}
      {qrDoc && (
        <div className="gp-modal-overlay" onClick={() => setQrDoc(null)}>
          <div
            className="gp-modal gp-qr-modal"
            role="dialog"
            aria-modal="true"
            aria-label="Booking Code"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              className="gp-detail-close gp-icon-button"
              aria-label="Close booking code"
              onClick={() => setQrDoc(null)}
            >
              <X size={17} />
            </button>
            <Ticket size={26} />
            <h2>{qrDoc.title || qrDoc.filename}</h2>
            <canvas ref={qrRef} />
            <strong>{qrDoc.booking_code}</strong>
            <p>
              {isPlannerDemo()
                ? 'Sample confirmation code. Not a valid travel or admission pass.'
                : 'This QR contains the confirmation code. Use your original provider ticket for travel.'}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
