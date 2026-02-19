import { useState, useEffect, useRef } from 'react'
import { Settings as SettingsIcon, Key, Cloud, Bell, Clock, Shield, Check, X, Loader2, Eye, EyeOff, ExternalLink } from 'lucide-react'

const API_BASE = '/api'

export default function Settings() {
  const [settings, setSettings] = useState({
    integration_mode: 'none',
    jobber_token: '',
    geoapify_api_key: '',
    notification_email: '',
    retention_days: 7
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [testingJobber, setTestingJobber] = useState(false)
  const [testingGeoapify, setTestingGeoapify] = useState(false)
  const [jobberResult, setJobberResult] = useState(null)
  const [geoapifyResult, setGeoapifyResult] = useState(null)
  const [showChangePIN, setShowChangePIN] = useState(false)
  const [showJobberToken, setShowJobberToken] = useState(false)
  const [showGeoapifyKey, setShowGeoapifyKey] = useState(false)
  const [message, setMessage] = useState(null)
  const [jobberStatus, setJobberStatus] = useState({ connected: false, loading: true })

  useEffect(() => {
    fetchSettings()
    fetchJobberStatus()
  }, [])

  const fetchSettings = async () => {
    try {
      const res = await fetch(`${API_BASE}/settings`)
      const data = await res.json()
      setSettings({
        integration_mode: data.integration_mode || 'none',
        jobber_token: data.jobber_token || '',
        geoapify_api_key: data.geoapify_api_key || '',
        notification_email: data.notification_email || '',
        retention_days: data.retention_days || 7
      })
    } catch (err) {
      console.error('Failed to load settings:', err)
    } finally {
      setLoading(false)
    }
  }

  const fetchJobberStatus = async () => {
    try {
      const res = await fetch(`${API_BASE}/jobber/status`)
      const data = await res.json()
      setJobberStatus({ connected: data.connected, loading: false })
    } catch (err) {
      setJobberStatus({ connected: false, loading: false })
    }
  }

  const connectJobber = async () => {
    try {
      const res = await fetch(`${API_BASE}/jobber/auth-url`)
      const data = await res.json()
      window.location.href = data.authUrl
    } catch (err) {
      setMessage({ type: 'error', text: 'Failed to get Jobber authorization URL' })
    }
  }

  const handleSave = async () => {
    setSaving(true)
    setMessage(null)

    try {
      const res = await fetch(`${API_BASE}/settings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(settings)
      })
      const data = await res.json()

      if (data.success) {
        setMessage({ type: 'success', text: 'Settings saved successfully' })
        fetchSettings()
      } else {
        setMessage({ type: 'error', text: data.error || 'Failed to save settings' })
      }
    } catch (err) {
      setMessage({ type: 'error', text: 'Connection error' })
    } finally {
      setSaving(false)
    }
  }

  const testJobber = async () => {
    setTestingJobber(true)
    setJobberResult(null)

    try {
      const res = await fetch(`${API_BASE}/settings/test-jobber`, { method: 'POST' })
      const data = await res.json()
      setJobberResult(data)
    } catch (err) {
      setJobberResult({ success: false, error: 'Connection failed' })
    } finally {
      setTestingJobber(false)
    }
  }

  const testGeoapify = async () => {
    setTestingGeoapify(true)
    setGeoapifyResult(null)

    try {
      const res = await fetch(`${API_BASE}/settings/test-geoapify`, { method: 'POST' })
      const data = await res.json()
      setGeoapifyResult(data)
    } catch (err) {
      setGeoapifyResult({ success: false, error: 'Connection failed' })
    } finally {
      setTestingGeoapify(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-8 h-8 text-gray-400 animate-spin" />
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <SettingsIcon className="w-6 h-6 text-primary-600" />
        Settings
      </h2>

      {message && (
        <div className={`rounded-lg p-4 mb-6 flex items-center gap-2 ${
          message.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
        }`}>
          {message.type === 'success' ? <Check className="w-5 h-5" /> : <X className="w-5 h-5" />}
          {message.text}
        </div>
      )}

      <div className="card mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <Cloud className="w-5 h-5 text-primary-600" />
          Jobber Integration
        </h3>

        <div className="space-y-4">
          {/* Jobber OAuth Connection */}
          <div className={`p-4 rounded-lg border-2 ${jobberStatus.connected ? 'bg-green-50 border-green-300' : 'bg-gray-50 border-gray-200'}`}>
            <div className="flex items-center justify-between">
              <div>
                <p className="font-semibold text-gray-900 flex items-center gap-2">
                  {jobberStatus.loading ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : jobberStatus.connected ? (
                    <span className="text-green-600">✅</span>
                  ) : (
                    <span className="text-gray-400">○</span>
                  )}
                  Jobber Account
                </p>
                <p className="text-sm text-gray-600 mt-1">
                  {jobberStatus.connected 
                    ? 'Connected - permit lookups can sync to Jobber'
                    : 'Not connected - click to authorize'}
                </p>
              </div>
              {!jobberStatus.connected && !jobberStatus.loading && (
                <button
                  onClick={connectJobber}
                  className="btn-primary flex items-center gap-2"
                >
                  <ExternalLink className="w-4 h-4" />
                  Connect Jobber
                </button>
              )}
            </div>
          </div>

          <p className="text-xs text-gray-500">
            When connected, permit lookup results can be synced to Jobber as client notes.
          </p>
        </div>
      </div>

      <div className="card mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <Key className="w-5 h-5 text-primary-600" />
          Address Autocomplete
        </h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Geoapify API Key</label>
          <div className="flex gap-2">
            <div className="relative flex-1">
              <input
                type={showGeoapifyKey ? 'text' : 'password'}
                value={settings.geoapify_api_key}
                onChange={(e) => setSettings(prev => ({ ...prev, geoapify_api_key: e.target.value }))}
                className="input-field pr-10"
                placeholder="Enter API key"
              />
              <button
                type="button"
                onClick={() => setShowGeoapifyKey(!showGeoapifyKey)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showGeoapifyKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            <button
              onClick={testGeoapify}
              disabled={testingGeoapify}
              className="btn-secondary whitespace-nowrap"
            >
              {testingGeoapify ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Test'}
            </button>
          </div>
          {geoapifyResult && (
            <p className={`text-sm mt-1 ${geoapifyResult.success ? 'text-green-600' : 'text-red-600'}`}>
              {geoapifyResult.success ? '✓ Connection successful' : `✗ ${geoapifyResult.error}`}
            </p>
          )}
          <p className="text-xs text-gray-500 mt-2">
            Get a free API key at <a href="https://www.geoapify.com/" target="_blank" rel="noopener noreferrer" className="text-primary-600 hover:underline">geoapify.com</a>
          </p>
        </div>
      </div>

      <div className="card mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <Bell className="w-5 h-5 text-primary-600" />
          Notifications
        </h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Notification Email</label>
          <input
            type="email"
            value={settings.notification_email}
            onChange={(e) => setSettings(prev => ({ ...prev, notification_email: e.target.value }))}
            className="input-field"
            placeholder="admin@example.com"
          />
        </div>
      </div>

      <div className="card mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <Clock className="w-5 h-5 text-primary-600" />
          Data Retention
        </h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Retention Period (days)</label>
          <input
            type="number"
            value={settings.retention_days}
            onChange={(e) => setSettings(prev => ({ ...prev, retention_days: parseInt(e.target.value) || 7 }))}
            className="input-field w-32"
            min="1"
            max="365"
          />
          <p className="text-xs text-gray-500 mt-1">
            Enquiries older than this will be automatically deleted
          </p>
        </div>
      </div>

      <div className="card mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <Shield className="w-5 h-5 text-primary-600" />
          Security
        </h3>

        <button
          onClick={() => setShowChangePIN(true)}
          className="btn-secondary"
        >
          Change PIN
        </button>
      </div>

      <button
        onClick={handleSave}
        disabled={saving}
        className="btn-primary w-full py-3 flex items-center justify-center gap-2"
      >
        {saving ? (
          <>
            <Loader2 className="w-5 h-5 animate-spin" />
            Saving...
          </>
        ) : (
          <>
            <Check className="w-5 h-5" />
            Save Settings
          </>
        )}
      </button>

      {showChangePIN && (
        <ChangePINModal onClose={() => setShowChangePIN(false)} />
      )}
    </div>
  )
}

function ChangePINModal({ onClose }) {
  const [currentPin, setCurrentPin] = useState(['', '', '', ''])
  const [newPin, setNewPin] = useState(['', '', '', ''])
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  const [loading, setLoading] = useState(false)
  const currentRefs = [useRef(), useRef(), useRef(), useRef()]
  const newRefs = [useRef(), useRef(), useRef(), useRef()]

  const handlePinChange = (index, value, isCurrent) => {
    if (!/^\d*$/.test(value)) return

    const arr = isCurrent ? [...currentPin] : [...newPin]
    const refs = isCurrent ? currentRefs : newRefs
    const setter = isCurrent ? setCurrentPin : setNewPin

    arr[index] = value.slice(-1)
    setter(arr)

    if (value && index < 3) {
      refs[index + 1].current?.focus()
    }
  }

  const handleSubmit = async () => {
    const current = currentPin.join('')
    const newCode = newPin.join('')

    if (current.length !== 4 || newCode.length !== 4) {
      setError('Please enter both PINs')
      return
    }

    setLoading(true)
    setError('')

    try {
      const res = await fetch(`${API_BASE}/change-pin`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ current_pin: current, new_pin: newCode })
      })
      const data = await res.json()

      if (data.success) {
        setSuccess(true)
        setTimeout(onClose, 1500)
      } else {
        setError(data.error || 'Failed to change PIN')
      }
    } catch (err) {
      setError('Connection error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="card max-w-md w-full">
        <h3 className="text-xl font-bold text-gray-900 mb-6">Change PIN</h3>

        {success ? (
          <div className="text-center py-6">
            <Check className="w-12 h-12 text-green-500 mx-auto mb-2" />
            <p className="text-green-700 font-medium">PIN changed successfully!</p>
          </div>
        ) : (
          <>
            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Current PIN</label>
                <div className="flex justify-center gap-3">
                  {currentPin.map((digit, i) => (
                    <input
                      key={i}
                      ref={currentRefs[i]}
                      type="password"
                      inputMode="numeric"
                      maxLength={1}
                      value={digit}
                      onChange={(e) => handlePinChange(i, e.target.value, true)}
                      className="pin-input"
                    />
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">New PIN</label>
                <div className="flex justify-center gap-3">
                  {newPin.map((digit, i) => (
                    <input
                      key={i}
                      ref={newRefs[i]}
                      type="password"
                      inputMode="numeric"
                      maxLength={1}
                      value={digit}
                      onChange={(e) => handlePinChange(i, e.target.value, false)}
                      className="pin-input"
                    />
                  ))}
                </div>
              </div>
            </div>

            {error && (
              <p className="text-red-600 text-sm text-center mt-4">{error}</p>
            )}

            <div className="flex gap-3 mt-6">
              <button onClick={onClose} className="btn-secondary flex-1">
                Cancel
              </button>
              <button
                onClick={handleSubmit}
                disabled={loading}
                className="btn-primary flex-1"
              >
                {loading ? <Loader2 className="w-4 h-4 animate-spin mx-auto" /> : 'Change PIN'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
