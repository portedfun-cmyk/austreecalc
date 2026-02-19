import { useState, useEffect } from 'react'
import { CheckCircle, AlertTriangle, Copy, Check, Download, Send, ExternalLink, PlusCircle, Loader2 } from 'lucide-react'

const API_BASE = '/api'

export default function EnquiryResult({ enquiry, guidance, onNewEnquiry, showSaveOption = false }) {
  const [localGuidance, setLocalGuidance] = useState(guidance)
  const [copied, setCopied] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [syncResult, setSyncResult] = useState(null)
  const [exporting, setExporting] = useState(false)

  useEffect(() => {
    if (!guidance && enquiry?.id) {
      fetchEnquiry()
    }
  }, [enquiry, guidance])

  const fetchEnquiry = async () => {
    try {
      const res = await fetch(`${API_BASE}/enquiry/${enquiry.id}`)
      const data = await res.json()
      if (data.permit_summary) {
        setLocalGuidance({
          confidence_flag: data.confidence_flag,
          formatted_summary: data.permit_summary
        })
      }
    } catch (err) {
      console.error('Failed to fetch enquiry:', err)
    }
  }

  const handleCopy = async () => {
    const text = localGuidance?.formatted_summary || formatGuidanceText()
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Copy failed:', err)
    }
  }

  const formatGuidanceText = () => {
    if (!localGuidance) return ''
    
    let text = `=== TREE PERMIT ENQUIRY ===\n`
    text += `Date: ${new Date(enquiry?.created_at || Date.now()).toLocaleString('en-AU')}\n`
    text += `Site Address: ${enquiry?.tree_address || ''}\n`
    text += `Client: ${enquiry?.client_name || ''}\n\n`
    text += `${localGuidance.confidence_flag}\n\n`

    if (localGuidance.quick_summary) {
      text += `QUICK SUMMARY\n`
      localGuidance.quick_summary.forEach(item => {
        text += `${item}\n`
      })
      text += '\n'
    }

    if (localGuidance.planning_controls) {
      text += `PLANNING CONTROLS\n${localGuidance.planning_controls.content}\n`
      localGuidance.planning_controls.sources?.forEach(s => {
        text += `Source: ${s.title} - ${s.url}\n`
      })
      text += '\n'
    }

    if (localGuidance.canopy_tree_controls) {
      text += `CANOPY TREE CONTROLS\n${localGuidance.canopy_tree_controls.content}\n`
      localGuidance.canopy_tree_controls.sources?.forEach(s => {
        text += `Source: ${s.title} - ${s.url}\n`
      })
      text += '\n'
    }

    if (localGuidance.native_veg_controls) {
      text += `NATIVE VEGETATION\n${localGuidance.native_veg_controls.content}\n`
      localGuidance.native_veg_controls.sources?.forEach(s => {
        text += `Source: ${s.title} - ${s.url}\n`
      })
      text += '\n'
    }

    if (localGuidance.council_local_law) {
      text += `COUNCIL LOCAL LAW\n${localGuidance.council_local_law.content}\n`
      localGuidance.council_local_law.sources?.forEach(s => {
        text += `Source: ${s.title} - ${s.url}\n`
      })
      text += '\n'
    }

    if (localGuidance.what_we_need_next) {
      text += `WHAT WE NEED NEXT\n`
      localGuidance.what_we_need_next.forEach(item => {
        if (typeof item === 'object' && item !== null && item.item) {
          text += `${item.item}\n`
          if (item.details && Array.isArray(item.details)) {
            item.details.forEach(detail => {
              const detailText = typeof detail === 'string' ? detail : JSON.stringify(detail);
              text += `  • ${detailText}\n`
            })
          }
        } else {
          const itemText = typeof item === 'string' ? item : JSON.stringify(item);
          text += `${itemText}\n`
        }
      })
      text += '\n'
    }

    if (localGuidance.immediate_risk_clause) {
      text += `${localGuidance.immediate_risk_clause}\n\n`
    }

    if (localGuidance.disclaimer) {
      text += `${localGuidance.disclaimer}\n`
    }

    return text
  }

  const handleSync = async () => {
    if (!enquiry?.id) return
    
    setSyncing(true)
    setSyncResult(null)

    try {
      const res = await fetch(`${API_BASE}/enquiry/${enquiry.id}/sync`, {
        method: 'POST'
      })
      const data = await res.json()
      setSyncResult(data)
    } catch (err) {
      setSyncResult({ success: false, message: 'Connection error' })
    } finally {
      setSyncing(false)
    }
  }

  const handleExport = async () => {
    if (!enquiry?.id) return
    
    setExporting(true)
    try {
      const res = await fetch(`${API_BASE}/enquiry/${enquiry.id}/export`)
      const data = await res.json()
      if (data.success) {
        alert(`Exported to: ${data.filename}`)
      }
    } catch (err) {
      console.error('Export failed:', err)
    } finally {
      setExporting(false)
    }
  }

  const isVerified = localGuidance?.confidence_flag?.includes('Verified')
  const permitSummary = localGuidance?.permit_summary

  return (
    <div className="max-w-4xl mx-auto">
      {/* PERMIT SUMMARY - TOP OF PAGE */}
      {permitSummary && (
        <div className="card mb-6 border-2 border-gray-300">
          <h2 className="text-xl font-bold text-gray-900 mb-4">📋 PERMIT SUMMARY</h2>
          
          {/* LGA and Zone */}
          <div className="mb-4 p-3 bg-gray-100 rounded">
            <p className="text-lg font-semibold">
              {permitSummary.lga ? `${permitSummary.lga} Council` : 'Council not identified'}
            </p>
            {localGuidance?.live_planning_data?.zone && (
              <p className="text-sm text-gray-600">
                Zone: {localGuidance.live_planning_data.zone.code} - {localGuidance.live_planning_data.zone.name}
              </p>
            )}
          </div>

          {/* Overlays Found */}
          <div className="mb-4">
            <p className="font-semibold text-gray-900 mb-2">Overlays Found:</p>
            {permitSummary.overlaysFound && permitSummary.overlaysFound.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {permitSummary.overlaysFound.map((code, i) => (
                  <span key={i} className="px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm font-medium">
                    {code}
                  </span>
                ))}
              </div>
            ) : (
              <p className="text-gray-600">No planning overlays found on this property</p>
            )}
          </div>

          {/* BPA Status */}
          <div className={`mb-4 p-3 rounded border-2 ${permitSummary.bushfireProne ? 'bg-orange-50 border-orange-300' : 'bg-gray-50 border-gray-200'}`}>
            <p className="font-semibold flex items-center gap-2">
              {permitSummary.bushfireProne ? (
                <>
                  <span className="text-orange-600">🔥</span>
                  <span className="text-orange-800">BUSHFIRE PRONE AREA (BPA)</span>
                </>
              ) : (
                <>
                  <span className="text-gray-500">✓</span>
                  <span className="text-gray-700">Not in Bushfire Prone Area</span>
                </>
              )}
            </p>
            {permitSummary.bushfireProne && (
              <p className="text-sm text-orange-700 mt-1">
                10/50 rule may apply - can clear vegetation within 10m of dwelling without permit
              </p>
            )}
          </div>

          {/* Planning Permit Status */}
          <div className={`mb-4 p-4 rounded border-2 ${permitSummary.planningPermitRequired ? 'bg-red-50 border-red-300' : 'bg-green-50 border-green-300'}`}>
            <p className="font-bold text-lg flex items-center gap-2">
              {permitSummary.planningPermitRequired ? (
                <>
                  <span className="text-red-600">⚠️</span>
                  <span className="text-red-800">PLANNING PERMIT LIKELY REQUIRED</span>
                </>
              ) : (
                <>
                  <span className="text-green-600">✅</span>
                  <span className="text-green-800">NO PLANNING PERMIT REQUIRED</span>
                </>
              )}
            </p>
            {permitSummary.planningPermitReason && permitSummary.planningPermitReason.length > 0 && (
              <ul className="mt-2 text-sm">
                {permitSummary.planningPermitReason.map((reason, i) => (
                  <li key={i} className={permitSummary.planningPermitRequired ? 'text-red-700' : 'text-gray-600'}>
                    • {reason}
                  </li>
                ))}
              </ul>
            )}
          </div>

          {/* Council Local Law Permit Status */}
          <div className={`mb-4 p-4 rounded border-2 ${permitSummary.councilPermitRequired ? 'bg-amber-50 border-amber-300' : 'bg-green-50 border-green-300'}`}>
            <p className="font-bold text-lg flex items-center gap-2">
              {permitSummary.councilPermitRequired ? (
                <>
                  <span className="text-amber-600">📋</span>
                  <span className="text-amber-800">COUNCIL LOCAL LAW PERMIT MAY BE REQUIRED</span>
                </>
              ) : (
                <>
                  <span className="text-green-600">✅</span>
                  <span className="text-green-800">NO COUNCIL PERMIT REQUIRED</span>
                </>
              )}
            </p>
            {permitSummary.councilPermitReason && permitSummary.councilPermitReason.length > 0 && (
              <ul className="mt-2 text-sm">
                {permitSummary.councilPermitReason.map((reason, i) => (
                  <li key={i} className="text-amber-700">• {reason}</li>
                ))}
              </ul>
            )}
          </div>

          {/* BMO/BPA Exemptions */}
          {permitSummary.noPermitNeeded && permitSummary.noPermitReason && permitSummary.noPermitReason.length > 0 && (
            <div className="p-4 rounded border-2 bg-blue-50 border-blue-300">
              <p className="font-bold text-lg flex items-center gap-2">
                <span className="text-blue-600">💡</span>
                <span className="text-blue-800">POSSIBLE EXEMPTIONS</span>
              </p>
              <ul className="mt-2 text-sm text-blue-700">
                {permitSummary.noPermitReason.map((reason, i) => (
                  <li key={i}>• {reason}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      <div className={`rounded-xl p-4 mb-6 ${isVerified ? 'confidence-verified' : 'confidence-manual'}`}>
        <div className="flex items-center gap-3">
          {isVerified ? (
            <CheckCircle className="w-8 h-8 text-green-600" />
          ) : (
            <AlertTriangle className="w-8 h-8 text-amber-600" />
          )}
          <div>
            <h2 className="text-lg font-bold">{localGuidance?.confidence_flag}</h2>
            <p className="text-sm opacity-80">
              {isVerified 
                ? 'Official source links are available for all guidance'
                : 'Some information requires manual verification with the responsible authority'}
            </p>
          </div>
        </div>
      </div>

      <div className="card mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-gray-900">Enquiry Details</h3>
          <span className="text-sm text-gray-500">#{enquiry?.id}</span>
        </div>
        
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span className="text-gray-500">Client:</span>
            <span className="ml-2 font-medium">{enquiry?.client_name}</span>
          </div>
          <div>
            <span className="text-gray-500">Phone:</span>
            <span className="ml-2">{enquiry?.phone}</span>
          </div>
          <div className="col-span-2">
            <span className="text-gray-500">Address:</span>
            <span className="ml-2">{enquiry?.tree_address}</span>
          </div>
          <div>
            <span className="text-gray-500">Works:</span>
            <span className="ml-2 capitalize">{enquiry?.work_type}</span>
          </div>
          {enquiry?.immediate_risk && (
            <div className="col-span-2 text-red-600 font-medium flex items-center gap-1">
              <AlertTriangle className="w-4 h-4" />
              Immediate Risk Flagged
            </div>
          )}
        </div>
      </div>

      {localGuidance?.quick_summary && (
        <div className="card mb-6">
          <h3 className="text-lg font-bold text-gray-900 mb-3">Quick Summary</h3>
          <ul className="space-y-2">
            {localGuidance.quick_summary.map((item, i) => (
              <li key={i} className="text-gray-700">{item}</li>
            ))}
          </ul>
        </div>
      )}

      {localGuidance?.live_planning_data && localGuidance.live_planning_data.lookup_successful && (
        <div className="card mb-6 bg-green-50 border-green-200">
          <h3 className="text-lg font-bold text-gray-900 mb-3 flex items-center gap-2">
            <span className="text-green-600">✅</span>
            Live VicPlan Data
          </h3>
          
          {localGuidance.live_planning_data.zone && (
            <div className="mb-4 p-3 bg-white rounded border">
              <p className="font-semibold text-gray-900">Planning Zone:</p>
              <p className="text-gray-700">
                <strong>{localGuidance.live_planning_data.zone.code}</strong> - {localGuidance.live_planning_data.zone.name}
              </p>
              {localGuidance.live_planning_data.zone.lga && (
                <p className="text-sm text-gray-600">LGA: {localGuidance.live_planning_data.zone.lga}</p>
              )}
              {localGuidance.live_planning_data.zone.explanation && (
                <p className="text-sm text-gray-600 mt-2">
                  {localGuidance.live_planning_data.zone.explanation.whatItMeans}
                </p>
              )}
            </div>
          )}
          
          {localGuidance.live_planning_data.overlays && localGuidance.live_planning_data.overlays.length > 0 ? (
            <div>
              <p className="font-semibold text-gray-900 mb-2">Overlays Found on Property:</p>
              <div className="space-y-4">
                {localGuidance.live_planning_data.overlays.map((overlay, i) => (
                  <div key={i} className="p-4 bg-white rounded border">
                    <p className="font-bold text-gray-900 text-lg">{overlay.code} - {overlay.name}</p>
                    {overlay.explanation && (
                      <>
                        <p className="text-sm text-gray-700 mt-2">{overlay.explanation.description}</p>
                        
                        {overlay.explanation.phoneScript && (
                          <div className="mt-3 p-3 bg-blue-50 rounded border border-blue-200">
                            <p className="text-sm font-semibold text-blue-800 mb-1">📞 What to tell the caller:</p>
                            <p className="text-sm text-blue-900 italic">"{overlay.explanation.phoneScript}"</p>
                          </div>
                        )}
                        
                        <div className="mt-3 p-3 bg-amber-50 rounded border border-amber-200">
                          <p className="text-sm font-semibold text-amber-800">⚡ Quick Answer:</p>
                          <p className="text-sm text-amber-900">{overlay.explanation.whatItMeans}</p>
                        </div>
                        
                        {overlay.explanation.exemptions && overlay.explanation.exemptions.length > 0 && (
                          <div className="mt-3">
                            <p className="font-semibold text-gray-900 mb-2">✅ Possible Exemptions (No Permit Needed):</p>
                            <div className="space-y-2">
                              {overlay.explanation.exemptions.map((exemption, j) => (
                                <div key={j} className="p-3 bg-green-50 rounded border border-green-200">
                                  <p className="font-semibold text-green-800">{typeof exemption === 'object' ? exemption.name : exemption}</p>
                                  {typeof exemption === 'object' && (
                                    <>
                                      <p className="text-sm text-green-700 mt-1">{exemption.description}</p>
                                      {exemption.details && (
                                        <p className="text-sm text-gray-700 mt-1"><strong>Details:</strong> {exemption.details}</p>
                                      )}
                                      {exemption.applies && (
                                        <p className="text-xs text-gray-600 mt-1"><strong>When it applies:</strong> {exemption.applies}</p>
                                      )}
                                    </>
                                  )}
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                        
                        {overlay.explanation.permitProcess && (
                          <div className="mt-3 p-3 bg-gray-50 rounded border">
                            <p className="font-semibold text-gray-900 mb-2">📋 If Permit IS Required:</p>
                            <div className="text-sm text-gray-700 space-y-1">
                              <p><strong>Where to apply:</strong> {overlay.explanation.permitProcess.where}</p>
                              <p><strong>Cost:</strong> {overlay.explanation.permitProcess.cost}</p>
                              <p><strong>Timeframe:</strong> {overlay.explanation.permitProcess.timeframe}</p>
                              {overlay.explanation.permitProcess.requirements && (
                                <div className="mt-2">
                                  <p className="font-semibold">Requirements:</p>
                                  <ul className="list-disc list-inside text-gray-600">
                                    {overlay.explanation.permitProcess.requirements.map((req, k) => (
                                      <li key={k}>{req}</li>
                                    ))}
                                  </ul>
                                </div>
                              )}
                            </div>
                          </div>
                        )}
                        
                        {overlay.explanation.sourceUrl && (
                          <a
                            href={overlay.explanation.sourceUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-3"
                          >
                            <ExternalLink className="w-3 h-3" />
                            Official Source
                          </a>
                        )}
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-gray-700">No planning overlays found on this property. Check for council Local Law requirements.</p>
          )}
        </div>
      )}

      <GuidanceSection 
        title="Planning Controls" 
        section={localGuidance?.planning_controls} 
      />
      
      <GuidanceSection 
        title="Canopy Tree Controls" 
        section={localGuidance?.canopy_tree_controls} 
      />
      
      <GuidanceSection 
        title="Native Vegetation Controls" 
        section={localGuidance?.native_veg_controls} 
      />
      
      <GuidanceSection 
        title="Council Local Law" 
        section={localGuidance?.council_local_law} 
      />

      {localGuidance?.what_we_need_next_text && (
        <div className="card mb-6">
          <h3 className="text-lg font-bold text-gray-900 mb-3">What We Need Next</h3>
          <div className="space-y-2 text-gray-700 whitespace-pre-line">
            {localGuidance.what_we_need_next_text.map((text, i) => (
              <div key={i}>{text}</div>
            ))}
          </div>
        </div>
      )}

      {localGuidance?.immediate_risk_clause && (
        <div className="card mb-6 border-red-200 bg-red-50">
          <h3 className="text-lg font-bold text-red-800 mb-3 flex items-center gap-2">
            <AlertTriangle className="w-5 h-5" />
            Immediate Risk Declaration
          </h3>
          <div className="text-red-700 whitespace-pre-line text-sm">
            {localGuidance.immediate_risk_clause}
          </div>
        </div>
      )}

      <div className="card mb-6 bg-gray-50">
        <h3 className="text-sm font-bold text-gray-600 mb-2">DISCLAIMER</h3>
        <p className="text-xs text-gray-500 whitespace-pre-line">
          {localGuidance?.disclaimer}
        </p>
      </div>

      {syncResult && (
        <div className={`rounded-lg p-4 mb-6 ${syncResult.success ? 'bg-green-50 border border-green-200' : 'bg-amber-50 border border-amber-200'}`}>
          <p className={syncResult.success ? 'text-green-700' : 'text-amber-700'}>
            {syncResult.message}
          </p>
          {syncResult.note && (
            <details className="mt-2">
              <summary className="text-sm cursor-pointer">View note for manual copy</summary>
              <pre className="mt-2 text-xs bg-white p-3 rounded border overflow-auto max-h-40">
                {syncResult.note}
              </pre>
            </details>
          )}
        </div>
      )}

      <div className="flex flex-wrap gap-3 mb-6">
        <button onClick={handleCopy} className="btn-secondary flex items-center gap-2">
          {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
          {copied ? 'Copied!' : 'Copy Note'}
        </button>

        {showSaveOption && (
          <button onClick={() => alert('Save functionality coming soon - this would save the lookup result to the enquiry list')} className="btn-secondary flex items-center gap-2">
            <Download className="w-4 h-4" />
            Save Result
          </button>
        )}

        {enquiry && (
          <button onClick={handleExport} disabled={exporting} className="btn-secondary flex items-center gap-2">
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        )}

        {enquiry && (
          <button onClick={handleSync} disabled={syncing} className="btn-primary flex items-center gap-2">
            {syncing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
            Sync to Jobber
          </button>
        )}

        <button onClick={onNewEnquiry} className="btn-primary flex items-center gap-2 ml-auto">
          <PlusCircle className="w-4 h-4" />
          {showSaveOption ? 'New Lookup' : 'New Enquiry'}
        </button>
      </div>
    </div>
  )
}

function GuidanceSection({ title, section }) {
  if (!section) return null

  return (
    <div className="card mb-6">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-bold text-gray-900">{title}</h3>
        {section.verified !== undefined && (
          <span className={`text-xs px-2 py-1 rounded ${section.verified ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>
            {section.verified ? '✓ Verified' : '⚠ Verify'}
          </span>
        )}
      </div>
      
      <div className="text-gray-700 whitespace-pre-line text-sm mb-4">
        {section.content}
      </div>

      {section.sources && section.sources.length > 0 && (
        <div className="border-t pt-3">
          <p className="text-xs text-gray-500 mb-2">Sources:</p>
          <div className="space-y-1">
            {section.sources.map((source, i) => (
              <a
                key={i}
                href={source.url}
                target="_blank"
                rel="noopener noreferrer"
                className="source-link flex items-center gap-1"
              >
                <ExternalLink className="w-3 h-3" />
                {source.title}
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
