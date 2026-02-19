import { useState, useEffect, useRef } from 'react'
import { User, Mail, Phone, MapPin, TreePine, AlertTriangle, Send, Loader2 } from 'lucide-react'

const API_BASE = '/api'

export default function EnquiryForm({ onSubmit, isOnline }) {
  const [formData, setFormData] = useState({
    client_name: '',
    email: '',
    phone: '',
    tree_address: '',
    tree_address_unit: '',
    tree_address_street: '',
    tree_address_suburb: '',
    tree_address_postcode: '',
    tree_address_state: '',
    tree_address_lat: 0,
    tree_address_lng: 0,
    billing_address: '',
    notes: '',
    species: '',
    height: '',
    dbh: '',
    num_trees: 1,
    work_type: 'pruning',
    immediate_risk: false,
    risk_notes: '',
    address_verified: false
  })

  const [suggestions, setSuggestions] = useState([])
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [addressError, setAddressError] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
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
      tree_address_lat: suggestion.lat || 0,
      tree_address_lng: suggestion.lng || 0,
      address_verified: true
    }))
    setSuggestions([])
    setShowSuggestions(false)
    setAddressError('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')

    if (!formData.client_name || !formData.email || !formData.phone || !formData.tree_address) {
      setError('Please fill in all required fields')
      return
    }

    setLoading(true)

    try {
      const payload = {
        ...formData,
        height: formData.height ? parseFloat(formData.height) : 0,
        dbh: formData.dbh ? parseFloat(formData.dbh) : 0,
        num_trees: parseInt(formData.num_trees) || 1
      }

      const res = await fetch(`${API_BASE}/enquiry`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })

      const data = await res.json()

      if (data.success) {
        onSubmit(data.enquiry, data.guidance)
      } else {
        setError(data.error || 'Failed to submit enquiry')
      }
    } catch (err) {
      setError('Connection error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-3xl mx-auto">
      <div className="card mb-6">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
          <User className="w-5 h-5 text-primary-600" />
          Client Details
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Client Name <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              name="client_name"
              value={formData.client_name}
              onChange={handleChange}
              className="input-field"
              placeholder="Full name"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="input-field pl-10"
                placeholder="email@example.com"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Phone <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                className="input-field pl-10"
                placeholder="0400 000 000"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Billing Address
            </label>
            <input
              type="text"
              name="billing_address"
              value={formData.billing_address}
              onChange={handleChange}
              className="input-field"
              placeholder="If different from tree location"
            />
          </div>
        </div>
      </div>

      <div className="card mb-6">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
          <MapPin className="w-5 h-5 text-primary-600" />
          Tree Location
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

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <textarea
              name="notes"
              value={formData.notes}
              onChange={handleChange}
              className="input-field"
              rows={3}
              placeholder="Access details, specific tree location on property, etc."
            />
          </div>
        </div>
      </div>

      <div className="card mb-6">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
          <TreePine className="w-5 h-5 text-primary-600" />
          Tree Details (Optional)
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
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
            <label className="block text-sm font-medium text-gray-700 mb-1">DBH/DSH (cm)</label>
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
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Number of Trees</label>
            <input
              type="number"
              name="num_trees"
              value={formData.num_trees}
              onChange={handleChange}
              className="input-field"
              min="1"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
      </div>

      <div className="card mb-6">
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

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700">{error}</p>
        </div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="btn-primary w-full py-3 text-lg flex items-center justify-center gap-2"
      >
        {loading ? (
          <>
            <Loader2 className="w-5 h-5 animate-spin" />
            Processing...
          </>
        ) : (
          <>
            <Send className="w-5 h-5" />
            Generate Permit Guidance
          </>
        )}
      </button>
    </form>
  )
}
