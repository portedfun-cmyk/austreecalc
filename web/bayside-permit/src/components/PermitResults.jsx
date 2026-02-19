import { useState } from 'react'
import { CheckCircle, AlertTriangle, Copy, Check, Send, ExternalLink, Edit2, Save, Phone, Loader2 } from 'lucide-react'

const API_BASE = '/api'

export default function PermitResults({ guidance, lookupData, onNewLookup }) {
  const [editMode, setEditMode] = useState(false)
  const [clientDetails, setClientDetails] = useState({
    client_name: lookupData?.client_name || '',
    phone: lookupData?.phone || '',
    email: lookupData?.email || '',
    tree_address: lookupData?.tree_address || '',
    work_type: lookupData?.work_type || 'removal',
    notes: ''
  })
  const [copied, setCopied] = useState(false)
  const [sendingToJobber, setSendingToJobber] = useState(false)
  const [jobberResult, setJobberResult] = useState(null)

  const permitSummary = guidance?.permit_summary || {}
  const livePlanningData = guidance?.live_planning_data || {}
  const overlays = livePlanningData.overlays || []
  const zone = livePlanningData.zone || null

  const handleCopy = async () => {
    const text = generateCallScript()
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Copy failed:', err)
    }
  }

  const sendToJobber = async () => {
    setSendingToJobber(true)
    setJobberResult(null)
    
    try {
      const res = await fetch(`${API_BASE}/jobber/sync`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lookupData: { ...lookupData, ...clientDetails },
          guidance
        })
      })
      
      const data = await res.json()
      if (res.ok) {
        setJobberResult({ success: true, message: data.message })
      } else {
        setJobberResult({ success: false, message: data.error || 'Failed to sync' })
      }
    } catch (err) {
      setJobberResult({ success: false, message: err.message })
    } finally {
      setSendingToJobber(false)
    }
  }

  const generateCallScript = () => {
    let script = ''
    
    if (permitSummary.planningPermitRequired) {
      script += `Based on the overlays on your property, you will likely need a planning permit before we can do any tree work.\n\n`
    } else {
      script += `Good news! Based on the overlays, you probably don't need a planning permit for this work.\n\n`
    }
    
    if (permitSummary.councilPermitRequired) {
      script += `However, ${permitSummary.lga || 'your council'} has a Local Law that may require a permit for trees over a certain size. We'll need to check the tree measurements to confirm.\n\n`
    }
    
    if (permitSummary.bushfireProne) {
      script += `Your property is in a Bushfire Prone Area, which means the 10/50 rule applies. You can clear any vegetation within 10 metres of your house without a permit for fire safety.\n\n`
    }
    
    overlays.forEach(overlay => {
      if (overlay.explanation?.phoneScript) {
        script += `${overlay.explanation.phoneScript}\n\n`
      }
    })
    
    return script
  }

  // Determine which control takes precedence
  const getPrecedence = () => {
    const controls = []
    
    // Planning overlays that require permits
    overlays.forEach(overlay => {
      if (overlay.explanation?.permitRequired === true) {
        controls.push({
          type: 'Planning Overlay',
          name: overlay.code,
          fullName: overlay.explanation.name,
          priority: 1,
          permitRequired: true,
          reason: 'Planning permit required under this overlay'
        })
      }
    })
    
    // Zone canopy tree controls
    if (zone?.explanation?.canopyTreeControls) {
      controls.push({
        type: 'Canopy Tree Controls',
        name: 'Clause 52.37',
        fullName: 'Canopy Tree Controls',
        priority: 2,
        permitRequired: true,
        reason: 'Planning permit may be required for canopy trees'
      })
    }
    
    // Council local law
    if (permitSummary.councilPermitRequired) {
      controls.push({
        type: 'Council Local Law',
        name: permitSummary.lga,
        fullName: `${permitSummary.lga} Local Law`,
        priority: 3,
        permitRequired: true,
        reason: 'Council permit may be required based on tree size'
      })
    }
    
    // BMO exemption
    if (permitSummary.bushfireProne) {
      controls.push({
        type: 'Bushfire Exemption',
        name: 'BMO 10/50',
        fullName: 'Bushfire Management Overlay 10/50 Rule',
        priority: 0,
        permitRequired: false,
        reason: 'May exempt from permit within 10-50m of dwelling'
      })
    }
    
    return controls.sort((a, b) => a.priority - b.priority)
  }

  const precedenceControls = getPrecedence()

  return (
    <div className="max-w-7xl mx-auto">
      {/* QUICK ANSWER BANNER - VERY TOP */}
      <div className={`mb-6 p-6 rounded-xl border-4 ${
        (permitSummary.planningPermitRequired || permitSummary.councilPermitRequired)
          ? 'bg-red-100 border-red-500' 
          : 'bg-green-100 border-green-500'
      }`}>
        <div className="text-center">
          <p className="text-sm text-gray-600 mb-1 uppercase font-medium">
            For {permitSummary.workType === 'pruning' ? 'PRUNING' : permitSummary.workType === 'removal' ? 'REMOVAL' : permitSummary.workType?.toUpperCase() || 'TREE WORK'}
          </p>
          <p className="text-3xl font-black mb-2">
            {(permitSummary.planningPermitRequired || permitSummary.councilPermitRequired) ? (
              <span className="text-red-700">⚠️ PERMIT REQUIRED</span>
            ) : (
              <span className="text-green-700">✅ NO PERMIT NEEDED</span>
            )}
          </p>
          
          {/* Show which permits are needed */}
          <div className="flex flex-wrap justify-center gap-3 mt-3">
            {permitSummary.planningPermitRequired && (
              <span className="px-4 py-2 bg-red-200 text-red-800 rounded-full font-bold">
                Planning Permit Required
              </span>
            )}
            {permitSummary.councilPermitRequired && (
              <span className="px-4 py-2 bg-amber-200 text-amber-800 rounded-full font-bold">
                Council Local Law Permit Required
              </span>
            )}
            {!permitSummary.planningPermitRequired && !permitSummary.councilPermitRequired && (
              <span className="px-4 py-2 bg-green-200 text-green-800 rounded-full font-bold">
                No Permits Required
              </span>
            )}
          </div>

          <p className="text-lg font-medium text-gray-700 mt-3">
            {permitSummary.lga && `${permitSummary.lga} Council`}
            {permitSummary.overlaysFound?.length > 0 && ` • Overlays: ${permitSummary.overlaysFound.join(', ')}`}
            {permitSummary.bushfireProne && ' • 🔥 Bushfire Prone Area'}
          </p>
          
          {permitSummary.bushfireProne && (
            <p className="text-blue-700 font-medium mt-2">
              💡 10/50 Rule: Can clear within 10m of dwelling without permit
            </p>
          )}
        </div>
      </div>

      {/* EDITABLE CLIENT DETAILS */}
      <div className="card mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-gray-900">Enquiry Details</h3>
          <button
            onClick={() => setEditMode(!editMode)}
            className="btn-secondary flex items-center gap-2 text-sm"
          >
            {editMode ? <Save className="w-4 h-4" /> : <Edit2 className="w-4 h-4" />}
            {editMode ? 'Done' : 'Edit'}
          </button>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-xs text-gray-500 mb-1">Client Name</label>
            {editMode ? (
              <input
                type="text"
                value={clientDetails.client_name}
                onChange={(e) => setClientDetails(prev => ({ ...prev, client_name: e.target.value }))}
                className="input-field text-sm"
                placeholder="Enter name"
              />
            ) : (
              <p className="font-medium">{clientDetails.client_name || '-'}</p>
            )}
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Phone</label>
            {editMode ? (
              <input
                type="tel"
                value={clientDetails.phone}
                onChange={(e) => setClientDetails(prev => ({ ...prev, phone: e.target.value }))}
                className="input-field text-sm"
                placeholder="Enter phone"
              />
            ) : (
              <p className="font-medium">{clientDetails.phone || '-'}</p>
            )}
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Email</label>
            {editMode ? (
              <input
                type="email"
                value={clientDetails.email}
                onChange={(e) => setClientDetails(prev => ({ ...prev, email: e.target.value }))}
                className="input-field text-sm"
                placeholder="Enter email"
              />
            ) : (
              <p className="font-medium">{clientDetails.email || '-'}</p>
            )}
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Work Type</label>
            {editMode ? (
              <select
                value={clientDetails.work_type}
                onChange={(e) => setClientDetails(prev => ({ ...prev, work_type: e.target.value }))}
                className="input-field text-sm"
              >
                <option value="removal">Removal</option>
                <option value="pruning">Pruning</option>
                <option value="stump_grinding">Stump Grinding</option>
                <option value="assessment">Assessment</option>
              </select>
            ) : (
              <p className="font-medium capitalize">{clientDetails.work_type || '-'}</p>
            )}
          </div>
          <div className="col-span-2 md:col-span-4">
            <label className="block text-xs text-gray-500 mb-1">Address</label>
            <p className="font-medium">{clientDetails.tree_address || lookupData?.tree_address || '-'}</p>
          </div>
          {editMode && (
            <div className="col-span-2 md:col-span-4">
              <label className="block text-xs text-gray-500 mb-1">Notes</label>
              <textarea
                value={clientDetails.notes}
                onChange={(e) => setClientDetails(prev => ({ ...prev, notes: e.target.value }))}
                className="input-field text-sm"
                rows={2}
                placeholder="Add any notes..."
              />
            </div>
          )}
        </div>
      </div>

      {/* TWO COLUMN LAYOUT */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* LEFT COLUMN - Overlays, Permits, LGA */}
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-gray-900 border-b pb-2">Planning Controls & Overlays</h3>
          
          {/* Zone Info */}
          {zone && (
            <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
              <p className="font-semibold text-blue-900">Planning Zone</p>
              <p className="text-blue-800">{zone.code} - {zone.name}</p>
              {zone.lga && <p className="text-sm text-blue-700">LGA: {zone.lga}</p>}
              {zone.explanation?.whatItMeans && (
                <p className="text-sm text-blue-600 mt-2">{zone.explanation.whatItMeans}</p>
              )}
            </div>
          )}

          {/* BPA Status */}
          <div className={`p-4 rounded-lg border-2 ${permitSummary.bushfireProne ? 'bg-orange-50 border-orange-300' : 'bg-gray-50 border-gray-200'}`}>
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
              <div className="mt-2 text-sm text-orange-700">
                <p className="font-medium">10/50 Rule Applies:</p>
                <ul className="mt-1 space-y-1">
                  <li>• Within 10m of dwelling: Clear ANY vegetation without permit</li>
                  <li>• 10-50m from dwelling: Remove fire risk vegetation without permit</li>
                </ul>
              </div>
            )}
          </div>

          {/* Overlays */}
          {overlays.length > 0 ? (
            overlays.map((overlay, i) => (
              <div key={i} className="p-4 bg-white rounded-lg border shadow-sm">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-bold text-gray-900">{overlay.code}</p>
                    <p className="text-sm text-gray-600">{overlay.name}</p>
                  </div>
                  {overlay.explanation?.permitRequired === true && (
                    <span className="px-2 py-1 bg-red-100 text-red-800 text-xs font-medium rounded">
                      PERMIT REQUIRED
                    </span>
                  )}
                  {overlay.explanation?.permitRequired === 'conditional' && (
                    <span className="px-2 py-1 bg-amber-100 text-amber-800 text-xs font-medium rounded">
                      CHECK SCHEDULE
                    </span>
                  )}
                  {overlay.explanation?.permitRequired === false && (
                    <span className="px-2 py-1 bg-green-100 text-green-800 text-xs font-medium rounded">
                      NO RESTRICTION
                    </span>
                  )}
                </div>
                
                {overlay.explanation && (
                  <div className="mt-3 text-sm">
                    <p className="text-gray-700">{overlay.explanation.description}</p>
                    
                    {overlay.explanation.exemptions && overlay.explanation.exemptions.length > 0 && (
                      <details className="mt-2">
                        <summary className="cursor-pointer text-green-700 font-medium">
                          View Exemptions ({overlay.explanation.exemptions.length})
                        </summary>
                        <div className="mt-2 space-y-2 pl-2 border-l-2 border-green-200">
                          {overlay.explanation.exemptions.map((ex, j) => (
                            <div key={j} className="text-sm">
                              <p className="font-medium text-green-800">
                                {typeof ex === 'object' ? ex.name : ex}
                              </p>
                              {typeof ex === 'object' && ex.description && (
                                <p className="text-gray-600">{ex.description}</p>
                              )}
                              {typeof ex === 'object' && ex.details && (
                                <p className="text-gray-500 text-xs mt-1">{ex.details}</p>
                              )}
                            </div>
                          ))}
                        </div>
                      </details>
                    )}
                    
                    {overlay.explanation.sourceUrl && (
                      <a
                        href={overlay.explanation.sourceUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-600 hover:underline text-xs flex items-center gap-1 mt-2"
                      >
                        <ExternalLink className="w-3 h-3" />
                        Official Source
                      </a>
                    )}
                  </div>
                )}
              </div>
            ))
          ) : (
            <div className="p-4 bg-green-50 rounded-lg border border-green-200">
              <p className="text-green-800 font-medium">No Planning Overlays Found</p>
              <p className="text-sm text-green-700">This property has no vegetation-related planning overlays.</p>
            </div>
          )}

          {/* LGA Local Law */}
          <div className="p-4 bg-amber-50 rounded-lg border border-amber-200">
            <p className="font-bold text-amber-900 flex items-center gap-2">
              📋 {permitSummary.lga || 'Council'} Local Law
            </p>
            <p className="text-sm text-amber-800 mt-2">
              Most Victorian councils require a permit for trees over a certain size (typically 5m+ height or 40cm+ trunk circumference).
            </p>
            <div className="mt-3 text-sm">
              <p className="font-medium text-amber-900">Common Exemptions:</p>
              <ul className="mt-1 text-amber-800 space-y-1">
                <li>• Dead trees (with evidence)</li>
                <li>• Immediate danger to life/property</li>
                <li>• Trees under size thresholds</li>
                <li>• Fruit trees and some species</li>
                <li>• Pruning less than 10% of canopy</li>
              </ul>
            </div>
            {guidance?.council_info?.tree_permit_url && (
              <a
                href={guidance.council_info.tree_permit_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:underline text-sm flex items-center gap-1 mt-3"
              >
                <ExternalLink className="w-3 h-3" />
                Council Tree Permits Page
              </a>
            )}
          </div>
        </div>

        {/* RIGHT COLUMN - Summary with Precedence */}
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-gray-900 border-b pb-2">Permit Summary</h3>
          
          {/* Quick Status */}
          <div className={`p-4 rounded-lg border-2 ${permitSummary.planningPermitRequired ? 'bg-red-50 border-red-300' : 'bg-green-50 border-green-300'}`}>
            <p className="font-bold text-xl flex items-center gap-2">
              {permitSummary.planningPermitRequired ? (
                <>
                  <AlertTriangle className="w-6 h-6 text-red-600" />
                  <span className="text-red-800">PLANNING PERMIT LIKELY REQUIRED</span>
                </>
              ) : (
                <>
                  <CheckCircle className="w-6 h-6 text-green-600" />
                  <span className="text-green-800">NO PLANNING PERMIT REQUIRED</span>
                </>
              )}
            </p>
          </div>

          <div className={`p-4 rounded-lg border-2 ${permitSummary.councilPermitRequired ? 'bg-amber-50 border-amber-300' : 'bg-green-50 border-green-300'}`}>
            <p className="font-bold text-lg flex items-center gap-2">
              {permitSummary.councilPermitRequired ? (
                <>
                  <AlertTriangle className="w-5 h-5 text-amber-600" />
                  <span className="text-amber-800">COUNCIL PERMIT MAY BE REQUIRED</span>
                </>
              ) : (
                <>
                  <CheckCircle className="w-5 h-5 text-green-600" />
                  <span className="text-green-800">NO COUNCIL PERMIT REQUIRED</span>
                </>
              )}
            </p>
          </div>

          {/* Precedence Order */}
          <div className="p-4 bg-gray-50 rounded-lg border">
            <p className="font-bold text-gray-900 mb-3">Control Hierarchy (Most Restrictive First)</p>
            <div className="space-y-2">
              {precedenceControls.length > 0 ? (
                precedenceControls.map((control, i) => (
                  <div 
                    key={i} 
                    className={`p-3 rounded border-l-4 ${
                      control.permitRequired 
                        ? 'bg-red-50 border-red-500' 
                        : 'bg-green-50 border-green-500'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-semibold text-gray-900">{i + 1}. {control.name}</p>
                        <p className="text-sm text-gray-600">{control.type}</p>
                      </div>
                      <span className={`text-xs font-medium px-2 py-1 rounded ${
                        control.permitRequired 
                          ? 'bg-red-100 text-red-800' 
                          : 'bg-green-100 text-green-800'
                      }`}>
                        {control.permitRequired ? 'PERMIT' : 'EXEMPT'}
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">{control.reason}</p>
                  </div>
                ))
              ) : (
                <p className="text-gray-600">No specific controls identified</p>
              )}
            </div>
          </div>

          {/* Overlays Found Badge List */}
          <div className="p-4 bg-white rounded-lg border">
            <p className="font-bold text-gray-900 mb-2">Overlays on Property</p>
            <div className="flex flex-wrap gap-2">
              {permitSummary.overlaysFound && permitSummary.overlaysFound.length > 0 ? (
                permitSummary.overlaysFound.map((code, i) => (
                  <span key={i} className="px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm font-medium">
                    {code}
                  </span>
                ))
              ) : (
                <span className="text-gray-500">None</span>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* CALL SCRIPT - MIDDLE */}
      <div className="card mb-6 bg-blue-50 border-blue-200">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
            <Phone className="w-5 h-5 text-blue-600" />
            Call Script
          </h3>
          <button
            onClick={handleCopy}
            className="btn-secondary flex items-center gap-2 text-sm"
          >
            {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
            {copied ? 'Copied!' : 'Copy Script'}
          </button>
        </div>
        
        <div className="bg-white p-4 rounded-lg border">
          {overlays.map((overlay, i) => (
            overlay.explanation?.phoneScript && (
              <div key={i} className="mb-4 last:mb-0">
                <p className="text-xs text-gray-500 mb-1">{overlay.code}:</p>
                <p className="text-gray-800 italic">"{overlay.explanation.phoneScript}"</p>
              </div>
            )
          ))}
          
          {permitSummary.councilPermitRequired && (
            <div className="mb-4">
              <p className="text-xs text-gray-500 mb-1">Council Local Law:</p>
              <p className="text-gray-800 italic">
                "{permitSummary.lga || 'Your council'} also has a Local Law that may require a permit for trees over a certain size. 
                We'll need to measure the tree to confirm if a council permit is needed. 
                Typically this applies to trees over 5 metres tall or with a trunk over 40cm around."
              </p>
            </div>
          )}
          
          {permitSummary.bushfireProne && (
            <div className="mb-4">
              <p className="text-xs text-gray-500 mb-1">Bushfire Prone Area:</p>
              <p className="text-gray-800 italic">
                "Good news - your property is in a Bushfire Prone Area, which means the 10/50 rule applies. 
                You can clear any vegetation within 10 metres of your house without needing a permit for fire safety. 
                Between 10 and 50 metres, you can also remove vegetation that creates a fire risk."
              </p>
            </div>
          )}
          
          {!overlays.some(o => o.explanation?.phoneScript) && !permitSummary.councilPermitRequired && !permitSummary.bushfireProne && (
            <p className="text-gray-600 italic">
              "Based on our lookup, there don't appear to be any planning overlays on your property that would require a permit. 
              However, we should still check the tree measurements to confirm no council Local Law permit is needed."
            </p>
          )}
        </div>
      </div>

      {/* SEND TO JOBBER */}
      <div className="card mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-gray-900">Save to Jobber</h3>
            <p className="text-sm text-gray-600">Create or update client with permit lookup notes</p>
          </div>
          <button
            onClick={sendToJobber}
            disabled={sendingToJobber}
            className="btn-primary flex items-center gap-2"
          >
            {sendingToJobber ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Send className="w-4 h-4" />
            )}
            {sendingToJobber ? 'Sending...' : 'Send to Jobber'}
          </button>
        </div>
        
        {jobberResult && (
          <div className={`mt-4 p-3 rounded ${jobberResult.success ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'}`}>
            {jobberResult.success ? '✅' : '❌'} {jobberResult.message}
          </div>
        )}
      </div>

      {/* NEW LOOKUP BUTTON */}
      <div className="text-center">
        <button onClick={onNewLookup} className="btn-secondary">
          ← New Permit Lookup
        </button>
      </div>
    </div>
  )
}
