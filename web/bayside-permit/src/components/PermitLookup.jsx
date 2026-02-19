import { useState, useEffect, useRef } from 'react'
import { Search, MapPin, TreePine, AlertTriangle, Info, Loader2, ExternalLink } from 'lucide-react'

const API_BASE = '/api'

export default function PermitLookup({ onGuidanceGenerated, isOnline }) {
  const [formData, setFormData] = useState({
    tree_address: '',
    tree_address_suburb: '',
    tree_address_postcode: '',
    tree_address_state: '',
    species: '',
    height: '',
    dbh: '',
    canopy_diameter: '',
    work_type: 'pruning',
    immediate_risk: false,
    risk_notes: '',
    address_verified: false,
    is_native: false,
    is_boundary_tree: false,
    is_vacant_land: false
  })

  const [suggestions, setSuggestions] = useState([])
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [showDbhGuide, setShowDbhGuide] = useState(false)
  const [addressError, setAddressError] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [guidance, setGuidance] = useState(null)
  const searchTimeout = useRef(null)
  const addressRef = useRef(null)

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (addressRef.current && !addressRef.current.contains(e.target)) {
        setShowSuggestions(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }))
    setError('')
  }

  const handleAddressSearch = async (query) => {
    setFormData(prev => ({ 
      ...prev, 
      tree_address: query,
      address_verified: false 
    }))
    setAddressError('')

    if (searchTimeout.current) {
      clearTimeout(searchTimeout.current)
    }

    if (query.length < 3) {
      setSuggestions([])
      setShowSuggestions(false)
      return
    }

    searchTimeout.current = setTimeout(async () => {
      try {
        const res = await fetch(`${API_BASE}/address/autocomplete?q=${encodeURIComponent(query)}`)
        const data = await res.json()

        if (data.offline) {
          setSuggestions([])
          setShowSuggestions(false)
          return
        }

        if (data.suggestions && data.suggestions.length > 0) {
          setSuggestions(data.suggestions)
          setShowSuggestions(true)
        } else {
          setSuggestions([])
          setShowSuggestions(false)
        }
      } catch (err) {
        console.error('Address search failed:', err)
      }
    }, 300)
  }

  const selectAddress = (suggestion) => {
    const stateCode = suggestion.state_code || suggestion.state
    const isVic = stateCode === 'VIC' || stateCode === 'Victoria'

    if (!isVic) {
      setAddressError('Only Victorian addresses are supported.')
      setShowSuggestions(false)
      return
    }

    setFormData(prev => ({
      ...prev,
      tree_address: suggestion.formatted,
      tree_address_unit: suggestion.unit || '',
      tree_address_street: suggestion.street || '',
      tree_address_suburb: suggestion.suburb || suggestion.city || '',
      tree_address_postcode: suggestion.postcode || '',
      tree_address_state: 'VIC',
      tree_address_lat: suggestion.lat || null,
      tree_address_lng: suggestion.lng || null,
      address_verified: true
    }))
    setSuggestions([])
    setShowSuggestions(false)
    setAddressError('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')

    if (!formData.tree_address) {
      setError('Please enter a tree location address')
      return
    }

    setLoading(true)

    try {
      const params = new URLSearchParams({
        address: formData.tree_address,
        suburb: formData.tree_address_suburb,
        postcode: formData.tree_address_postcode,
        lat: formData.tree_address_lat || '',
        lng: formData.tree_address_lng || '',
        species: formData.species,
        height: formData.height || 0,
        dbh: formData.dbh || 0,
        canopy: formData.canopy_diameter || 0,
        work_type: formData.work_type,
        immediate_risk: formData.immediate_risk,
        address_verified: formData.address_verified,
        is_native: formData.is_native,
        is_boundary: formData.is_boundary_tree,
        is_vacant: formData.is_vacant_land
      })

      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 30000)
      
      const res = await fetch(`${API_BASE}/permit-guidance?${params}`, {
        signal: controller.signal
      })
      clearTimeout(timeoutId)
      
      const data = await res.json()

      if (res.ok) {
        setGuidance(data)
        onGuidanceGenerated({
          formData: formData,
          guidance: data
        })
      } else {
        setError(data.error || 'Failed to get permit guidance')
      }
    } catch (err) {
      setError('Connection error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const resetForm = () => {
    setFormData({
      tree_address: '',
      tree_address_suburb: '',
      tree_address_postcode: '',
      tree_address_state: '',
      species: '',
      height: '',
      dbh: '',
      canopy_diameter: '',
      work_type: 'pruning',
      immediate_risk: false,
      risk_notes: '',
      address_verified: false,
      is_native: false,
      is_boundary_tree: false,
      is_vacant_land: false
    })
    setGuidance(null)
    setError('')
    setAddressError('')
  }

  return (
    <div className="max-w-3xl mx-auto">
      <div className="card mb-6">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
          <Search className="w-5 h-5 text-primary-600" />
          Permit Lookup Tool
        </h2>

        <div className="space-y-4">
          <div ref={addressRef} className="relative">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Site Address <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <MapPin className="absolute left-3 top-3 w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={formData.tree_address}
                onChange={(e) => handleAddressSearch(e.target.value)}
                onFocus={() => suggestions.length > 0 && setShowSuggestions(true)}
                className={`input-field pl-10 ${formData.address_verified ? 'border-green-500 bg-green-50' : ''}`}
                placeholder="Start typing address..."
                required
              />
              {formData.address_verified && (
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-green-600 text-xs font-medium">
                  ✓ Verified
                </span>
              )}
            </div>

            {!isOnline && (
              <p className="text-amber-600 text-xs mt-1">
                Offline — enter address manually. Manual verification required.
              </p>
            )}

            {addressError && (
              <p className="text-red-600 text-sm mt-1">{addressError}</p>
            )}

            {showSuggestions && suggestions.length > 0 && (
              <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-auto">
                {suggestions.map((s, i) => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => selectAddress(s)}
                    className="w-full px-4 py-2 text-left hover:bg-gray-50 text-sm border-b last:border-b-0"
                  >
                    {s.formatted}
                  </button>
                ))}
              </div>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Species</label>
              <input
                type="text"
                name="species"
                value={formData.species}
                onChange={handleChange}
                className="input-field"
                placeholder="e.g., River Red Gum"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Height (m)</label>
              <input
                type="number"
                name="height"
                value={formData.height}
                onChange={handleChange}
                className="input-field"
                placeholder="e.g., 12"
                step="0.1"
                min="0"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">DBH (cm)</label>
              <input
                type="number"
                name="dbh"
                value={formData.dbh}
                onChange={handleChange}
                className="input-field"
                placeholder="e.g., 45"
                step="1"
                min="0"
              />
              <button
                type="button"
                onClick={() => setShowDbhGuide(!showDbhGuide)}
                className="text-xs text-blue-600 hover:text-blue-800 mt-1"
              >
                📏 Don't know DBH? Click for size guide
              </button>
            </div>
          </div>

          {/* DBH SIZE GUIDE */}
          {showDbhGuide && (
            <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
              <h4 className="font-bold text-gray-900 mb-3">📏 DBH Size Guide - Ask the Caller</h4>
              <p className="text-sm text-gray-600 mb-3">
                "Can you wrap your hands around the trunk at chest height? Or compare it to one of these items:"
              </p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🥤</div>
                  <p className="font-bold text-lg">~8cm</p>
                  <p className="text-xs text-gray-600">Coffee cup</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🫙</div>
                  <p className="font-bold text-lg">~10cm</p>
                  <p className="text-xs text-gray-600">Vegemite jar</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🥫</div>
                  <p className="font-bold text-lg">~15cm</p>
                  <p className="text-xs text-gray-600">Large tin can</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🍽️</div>
                  <p className="font-bold text-lg">~25cm</p>
                  <p className="text-xs text-gray-600">Dinner plate</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🏀</div>
                  <p className="font-bold text-lg">~30cm</p>
                  <p className="text-xs text-gray-600">Basketball</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🪣</div>
                  <p className="font-bold text-lg">~35cm</p>
                  <p className="text-xs text-gray-600">Bucket</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🛞</div>
                  <p className="font-bold text-lg">~40cm</p>
                  <p className="text-xs text-gray-600">Car steering wheel</p>
                </div>
                <div className="p-3 bg-white rounded border text-center">
                  <div className="text-2xl mb-1">🚲</div>
                  <p className="font-bold text-lg">~50cm+</p>
                  <p className="text-xs text-gray-600">Bike wheel</p>
                </div>
              </div>
              <div className="mt-3 p-2 bg-amber-50 rounded border border-amber-200">
                <p className="text-sm text-amber-800">
                  <strong>💡 Tip:</strong> "Can you hug the tree? If yes, it's probably under 40cm. If you can't get your arms around it, it's likely 50cm+"
                </p>
              </div>
              <div className="mt-2 p-2 bg-gray-100 rounded">
                <p className="text-xs text-gray-600">
                  <strong>Note:</strong> DBH = Diameter at Breast Height (1.4m from ground). Most council permits apply to trees with DBH over 40cm or trunk circumference over 125cm.
                </p>
              </div>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Canopy Diameter (m)</label>
              <input
                type="number"
                name="canopy_diameter"
                value={formData.canopy_diameter}
                onChange={handleChange}
                className="input-field"
                placeholder="e.g., 8"
                step="0.1"
                min="0"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Works Required</label>
              <select
                name="work_type"
                value={formData.work_type}
                onChange={handleChange}
                className="input-field"
              >
                <option value="pruning">Pruning</option>
                <option value="removal">Removal</option>
              </select>
            </div>
          </div>

          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="is_native"
                name="is_native"
                checked={formData.is_native}
                onChange={handleChange}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <label htmlFor="is_native" className="text-sm text-gray-700">
                Native Australian species
              </label>
            </div>

            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="is_boundary_tree"
                name="is_boundary_tree"
                checked={formData.is_boundary_tree}
                onChange={handleChange}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <label htmlFor="is_boundary_tree" className="text-sm text-gray-700">
                Within 6m of front boundary or 4.5m of rear boundary
              </label>
            </div>

            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="is_vacant_land"
                name="is_vacant_land"
                checked={formData.is_vacant_land}
                onChange={handleChange}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <label htmlFor="is_vacant_land" className="text-sm text-gray-700">
                Vacant land or new dwelling proposed
              </label>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="flex items-center h-5 mt-1">
              <input
                type="checkbox"
                id="immediate_risk"
                name="immediate_risk"
                checked={formData.immediate_risk}
                onChange={handleChange}
                className="w-5 h-5 text-red-600 border-gray-300 rounded focus:ring-red-500"
              />
            </div>
            <div className="flex-1">
              <label htmlFor="immediate_risk" className="flex items-center gap-2 text-lg font-semibold text-gray-900 cursor-pointer">
                <AlertTriangle className="w-5 h-5 text-red-500" />
                Immediate Risk to Life or Property
              </label>
              <p className="text-sm text-gray-600 mt-1">
                Check this if emergency works may be required before permit approval
              </p>

              {formData.immediate_risk && (
                <div className="mt-3">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Describe the immediate risk
                  </label>
                  <textarea
                    name="risk_notes"
                    value={formData.risk_notes}
                    onChange={handleChange}
                    className="input-field border-red-300"
                    rows={2}
                    placeholder="e.g., Large branch hanging over driveway, structural crack visible..."
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700">{error}</p>
        </div>
      )}

      <div className="flex gap-3 mb-6">
        <button
          type="button"
          onClick={handleSubmit}
          disabled={loading}
          className="btn-primary flex-1 py-3 text-lg flex items-center justify-center gap-2"
        >
          {loading ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              Processing...
            </>
          ) : (
            <>
              <Search className="w-5 h-5" />
              Get Permit Guidance
            </>
          )}
        </button>

        {guidance && (
          <button
            type="button"
            onClick={resetForm}
            className="btn-secondary"
          >
            Clear
          </button>
        )}
      </div>

      {guidance && (
        <div className="card">
          <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <Info className="w-5 h-5 text-primary-600" />
            Permit Guidance Results
          </h3>

          <div className={`rounded-xl p-4 mb-4 ${guidance.confidence_flag?.includes('Verified') ? 'confidence-verified' : 'confidence-manual'}`}>
            <div className="flex items-center gap-3">
              {guidance.confidence_flag?.includes('Verified') ? (
                <span className="text-green-600">✅</span>
              ) : (
                <span className="text-amber-600">⚠️</span>
              )}
              <div>
                <p className="font-semibold">{guidance.confidence_flag}</p>
              </div>
            </div>
          </div>

          {guidance.council_info && (
            <div className="mb-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
              <h4 className="font-semibold text-gray-900 mb-2">Council Information</h4>
              <p className="text-sm text-gray-700">
                <strong>{guidance.council_info.name}</strong>
              </p>
              {guidance.council_info.tree_permit_url && (
                <a
                  href={guidance.council_info.tree_permit_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-2"
                >
                  <ExternalLink className="w-3 h-3" />
                  Council Tree Permits
                </a>
              )}
              {guidance.council_info.local_law_url && (
                <a
                  href={guidance.council_info.local_law_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-1"
                >
                  <ExternalLink className="w-3 h-3" />
                  Local Law
                </a>
              )}
            </div>
          )}

          {guidance.permits_required && guidance.permits_required.length > 0 && (
            <div className="mb-4 p-4 bg-red-50 rounded-lg border border-red-200">
              <h4 className="font-semibold text-gray-900 mb-2">Permits Likely Required</h4>
              <ul className="space-y-1 text-sm text-gray-700">
                {guidance.permits_required.map((permit, i) => (
                  <li key={i} className="font-medium">• {permit}</li>
                ))}
              </ul>
            </div>
          )}

          {guidance.council_local_law && guidance.council_local_law.applies === 'YES' && (
            <div className="mb-4 p-4 bg-orange-50 rounded-lg border border-orange-200">
              <h4 className="font-semibold text-gray-900 mb-2">Council Local Law</h4>
              <p className="text-sm text-gray-700 mb-2">{guidance.council_local_law.description}</p>
              {guidance.council_local_law.threshold && (
                <p className="text-sm text-gray-700 mb-2">
                  <strong>Threshold:</strong> {guidance.council_local_law.threshold.description}
                </p>
              )}
              {guidance.council_local_law.sources && guidance.council_local_law.sources.map((source, i) => (
                <a
                  key={i}
                  href={source.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-1"
                >
                  <ExternalLink className="w-3 h-3" />
                  {source.title}
                </a>
              ))}
            </div>
          )}

          {guidance.native_veg && guidance.native_veg.applies === 'YES' && (
            <div className="mb-4 p-4 bg-green-50 rounded-lg border border-green-200">
              <h4 className="font-semibold text-gray-900 mb-2">Native Vegetation Controls</h4>
              <p className="text-sm text-gray-700 mb-2">{guidance.native_veg.description}</p>
              {guidance.native_veg.exemptions && guidance.native_veg.exemptions.length > 0 && (
                <div className="mt-2">
                  <p className="text-sm font-semibold text-gray-900">Exemptions:</p>
                  <ul className="space-y-1 text-sm text-gray-700 mt-1">
                    {guidance.native_veg.exemptions.map((exemption, i) => (
                      <li key={i}>
                        <strong>{exemption.name}:</strong> {exemption.description}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              {guidance.native_veg.sources && guidance.native_veg.sources.map((source, i) => (
                <a
                  key={i}
                  href={source.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-2"
                >
                  <ExternalLink className="w-3 h-3" />
                  {source.title}
                </a>
              ))}
            </div>
          )}

          {guidance.overlays_to_check && guidance.overlays_to_check.length > 0 && !guidance.live_planning_data?.lookup_successful && (
            <div className="mb-4 p-4 bg-purple-50 rounded-lg border border-purple-200">
              <h4 className="font-semibold text-gray-900 mb-2">Planning Overlays to Check</h4>
              <ul className="space-y-2 text-sm text-gray-700">
                {guidance.overlays_to_check.map((overlay, i) => (
                  <li key={i}>
                    <strong>{overlay.overlay}</strong>
                    <p className="text-gray-600 mt-1">{overlay.description}</p>
                    <p className="text-gray-600">{overlay.action}</p>
                    <p className="text-gray-600">{overlay.if_applies}</p>
                    {overlay.source && (
                      <a
                        href={overlay.source}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-1"
                      >
                        <ExternalLink className="w-3 h-3" />
                        Source
                      </a>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {guidance.live_planning_data && guidance.live_planning_data.lookup_successful && (
            <div className="mb-4 p-4 bg-green-50 rounded-lg border border-green-200">
              <h4 className="font-semibold text-gray-900 mb-2 flex items-center gap-2">
                <span className="text-green-600">✅</span>
                Live VicPlan Data Retrieved
              </h4>
              
              {guidance.live_planning_data.zone && (
                <div className="mb-3">
                  <p className="text-sm font-semibold text-gray-900">Planning Zone:</p>
                  <p className="text-sm text-gray-700">
                    <strong>{guidance.live_planning_data.zone.code}</strong> - {guidance.live_planning_data.zone.name}
                  </p>
                  {guidance.live_planning_data.zone.explanation && (
                    <p className="text-sm text-gray-600 mt-1">
                      {guidance.live_planning_data.zone.explanation.whatItMeans}
                    </p>
                  )}
                </div>
              )}
              
              {guidance.live_planning_data.overlays && guidance.live_planning_data.overlays.length > 0 ? (
                <div>
                  <p className="text-sm font-semibold text-gray-900 mb-2">Overlays Found on Property:</p>
                  <ul className="space-y-3">
                    {guidance.live_planning_data.overlays.map((overlay, i) => (
                      <li key={i} className="bg-white p-3 rounded border border-green-100">
                        <p className="font-semibold text-gray-900">{overlay.code} - {overlay.name}</p>
                        {overlay.explanation && (
                          <>
                            <p className="text-sm text-gray-700 mt-1">{overlay.explanation.description}</p>
                            <p className="text-sm text-gray-800 mt-2 font-medium">
                              What this means: {overlay.explanation.whatItMeans}
                            </p>
                            {overlay.explanation.exemptions && overlay.explanation.exemptions.length > 0 && (
                              <div className="mt-2">
                                <p className="text-sm font-semibold text-gray-700">Possible Exemptions:</p>
                                <ul className="text-sm text-gray-600 mt-1">
                                  {overlay.explanation.exemptions.map((exemption, j) => (
                                    <li key={j}>• {exemption}</li>
                                  ))}
                                </ul>
                              </div>
                            )}
                            {overlay.explanation.sourceUrl && (
                              <a
                                href={overlay.explanation.sourceUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-blue-600 hover:text-blue-800 text-sm flex items-center gap-1 mt-2"
                              >
                                <ExternalLink className="w-3 h-3" />
                                Official Source
                              </a>
                            )}
                          </>
                        )}
                      </li>
                    ))}
                  </ul>
                </div>
              ) : (
                <p className="text-sm text-gray-700">No planning overlays found on this property.</p>
              )}
            </div>
          )}

          {guidance.live_planning_data && !guidance.live_planning_data.lookup_successful && (
            <div className="mb-4 p-4 bg-amber-50 rounded-lg border border-amber-200">
              <h4 className="font-semibold text-gray-900 mb-2 flex items-center gap-2">
                <span className="text-amber-600">⚠️</span>
                VicPlan Lookup Unavailable
              </h4>
              <p className="text-sm text-gray-700">
                Could not retrieve live overlay data. Please check VicPlan manually for accurate overlay information.
              </p>
              <a href="https://mapshare.vic.gov.au/vicplan/" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline text-sm mt-2 block">
                Check VicPlan manually →
              </a>
            </div>
          )}

          {guidance.what_we_need_next_text && Array.isArray(guidance.what_we_need_next_text) && guidance.what_we_need_next_text.length > 0 && (
            <div className="mb-4 p-4 bg-gray-50 rounded-lg border border-gray-200">
              <h4 className="font-semibold text-gray-900 mb-2">What We Need Next</h4>
              <div className="text-sm text-gray-700 whitespace-pre-line">
                {guidance.what_we_need_next_text.map((text, i) => (
                  <div key={i}>{text}</div>
                ))}
              </div>
            </div>
          )}

          <div className="bg-yellow-50 rounded-lg p-3 text-xs text-gray-600 border border-yellow-200">
            <p className="font-semibold mb-1">Important:</p>
            <p>This is guidance only. All information must be verified with the relevant council before works commence. Check VicPlan for overlays on the property.</p>
            <a href="https://mapshare.vic.gov.au/vicplan/" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline mt-1 block">
              Check VicPlan for overlays →
            </a>
          </div>
        </div>
      )}
    </div>
  )
}
