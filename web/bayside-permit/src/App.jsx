import { useState, useEffect } from 'react'
import { Settings as SettingsIcon, Shield, Search } from 'lucide-react'
import PinOverlay from './components/PinOverlay'
import SetupScreen from './components/SetupScreen'
import PermitResults from './components/PermitResults'
import Settings from './components/Settings'
import PermitLookup from './components/PermitLookup'

const API_BASE = '/api'

function App() {
  const [appState, setAppState] = useState('loading')
  const [currentView, setCurrentView] = useState('lookup')
  const [currentGuidance, setCurrentGuidance] = useState(null)
  const [currentLookupData, setCurrentLookupData] = useState(null)
  const [isOnline, setIsOnline] = useState(navigator.onLine)

  useEffect(() => {
    checkStatus()
    
    // Check for Jobber OAuth callback
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.get('jobber_connected') === 'true') {
      // Clear the URL parameter
      window.history.replaceState({}, '', '/')
      // Show success message after auth
      setTimeout(() => {
        alert('Jobber connected successfully!')
      }, 500)
    }
    if (urlParams.get('jobber_error')) {
      const error = urlParams.get('jobber_error')
      window.history.replaceState({}, '', '/')
      setTimeout(() => {
        alert('Jobber connection failed: ' + error)
      }, 500)
    }
    
    const handleOnline = () => setIsOnline(true)
    const handleOffline = () => setIsOnline(false)
    
    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)
    
    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  const checkStatus = async () => {
    try {
      const res = await fetch(`${API_BASE}/status`)
      const data = await res.json()
      
      if (!data.setup_complete) {
        setAppState('setup')
      } else if (data.locked_out) {
        setAppState('lockout')
      } else {
        setAppState('pin')
      }
    } catch (err) {
      console.error('Status check failed:', err)
      setAppState('error')
    }
  }

  const handleSetupComplete = () => {
    setAppState('pin')
  }

  const handlePinSuccess = () => {
    setAppState('authenticated')
  }

  const handlePermitLookup = (lookupData) => {
    setCurrentGuidance(lookupData.guidance)
    setCurrentLookupData(lookupData.formData)
    setCurrentView('lookup-result')
  }

  if (appState === 'loading') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <img src="/logo.png" alt="Bayside Treeworks" className="w-24 h-24 mx-auto mb-4" onError={(e) => { e.target.style.display = 'none' }} />
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  if (appState === 'error') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center card max-w-md">
          <Shield className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-900 mb-2">Connection Error</h2>
          <p className="text-gray-600 mb-4">Unable to connect to the server. Make sure the application is running.</p>
          <button onClick={checkStatus} className="btn-primary">Retry</button>
        </div>
      </div>
    )
  }

  if (appState === 'setup') {
    return <SetupScreen onComplete={handleSetupComplete} />
  }

  if (appState === 'pin' || appState === 'lockout') {
    return <PinOverlay onSuccess={handlePinSuccess} />
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {!isOnline && (
        <div className="bg-amber-500 text-white px-4 py-2 text-center text-sm font-medium">
          Offline — autocomplete unavailable. Manual verification required for all permit guidance.
        </div>
      )}
      
      <header className="bg-white border-b border-gray-200 sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3 cursor-pointer" onClick={() => setCurrentView('lookup')}>
              <img src="/logo.png" alt="Bayside Treeworks" className="h-12 w-auto" onError={(e) => { e.target.style.display = 'none' }} />
              <div>
                <h1 className="text-lg font-bold text-gray-900">Bayside Treeworks</h1>
                <p className="text-xs text-gray-500">VIC Permit Lookup</p>
              </div>
            </div>
            
            <nav className="flex items-center gap-2">
              <button
                onClick={() => setCurrentView('lookup')}
                className={`nav-link flex items-center gap-2 ${currentView === 'lookup' || currentView === 'lookup-result' ? 'active' : ''}`}
              >
                <Search className="w-4 h-4" />
                <span className="hidden sm:inline">Permit Lookup</span>
              </button>
              <button
                onClick={() => setCurrentView('settings')}
                className={`nav-link flex items-center gap-2 ${currentView === 'settings' ? 'active' : ''}`}
              >
                <SettingsIcon className="w-4 h-4" />
                <span className="hidden sm:inline">Settings</span>
              </button>
            </nav>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {currentView === 'lookup' && (
          <PermitLookup onGuidanceGenerated={handlePermitLookup} isOnline={isOnline} />
        )}
        
        {currentView === 'lookup-result' && (
          <PermitResults 
            guidance={currentGuidance}
            lookupData={currentLookupData}
            onNewLookup={() => setCurrentView('lookup')}
          />
        )}
        
        {currentView === 'settings' && (
          <Settings />
        )}
      </main>

      <footer className="border-t border-gray-200 bg-white mt-auto">
        <div className="max-w-7xl mx-auto px-4 py-4 text-center text-sm text-gray-500">
          <p>Bayside Treeworks — Internal Use Only — Victoria, Australia</p>
          <p className="text-xs mt-1">All guidance requires verification with the responsible authority.</p>
        </div>
      </footer>
    </div>
  )
}

export default App
