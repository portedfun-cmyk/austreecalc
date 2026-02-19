import { useState, useRef } from 'react'
import { TreePine, Shield, Copy, Check, AlertTriangle } from 'lucide-react'

const API_BASE = '/api'

export default function SetupScreen({ onComplete }) {
  const [step, setStep] = useState('welcome')
  const [pin, setPin] = useState(['', '', '', ''])
  const [confirmPin, setConfirmPin] = useState(['', '', '', ''])
  const [error, setError] = useState('')
  const [recoveryKey, setRecoveryKey] = useState('')
  const [copied, setCopied] = useState(false)
  const pinRefs = [useRef(), useRef(), useRef(), useRef()]
  const confirmRefs = [useRef(), useRef(), useRef(), useRef()]

  const handlePinChange = (index, value, isConfirm = false) => {
    if (!/^\d*$/.test(value)) return
    
    const arr = isConfirm ? [...confirmPin] : [...pin]
    const refs = isConfirm ? confirmRefs : pinRefs
    
    arr[index] = value.slice(-1)
    isConfirm ? setConfirmPin(arr) : setPin(arr)
    setError('')

    if (value && index < 3) {
      refs[index + 1].current?.focus()
    }
  }

  const handleKeyDown = (index, e, isConfirm = false) => {
    const arr = isConfirm ? confirmPin : pin
    const refs = isConfirm ? confirmRefs : pinRefs
    
    if (e.key === 'Backspace' && !arr[index] && index > 0) {
      refs[index - 1].current?.focus()
    }
  }

  const handleSetPin = () => {
    const pinCode = pin.join('')
    if (pinCode.length !== 4) {
      setError('Please enter a 4-digit PIN')
      return
    }
    setStep('confirm')
    setTimeout(() => confirmRefs[0].current?.focus(), 100)
  }

  const handleConfirmPin = async () => {
    const pinCode = pin.join('')
    const confirmCode = confirmPin.join('')

    if (pinCode !== confirmCode) {
      setError('PINs do not match')
      setConfirmPin(['', '', '', ''])
      confirmRefs[0].current?.focus()
      return
    }

    try {
      const res = await fetch(`${API_BASE}/setup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin: pinCode })
      })
      const data = await res.json()

      if (data.success) {
        setRecoveryKey(data.recovery_key)
        setStep('recovery')
      } else {
        setError(data.error || 'Setup failed')
      }
    } catch (err) {
      setError('Connection error')
    }
  }

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(recoveryKey)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Copy failed')
    }
  }

  if (step === 'welcome') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-900 to-primary-700 p-4">
        <div className="card max-w-lg w-full text-center">
          <TreePine className="w-20 h-20 text-primary-600 mx-auto mb-6" />
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Bayside Tree Works</h1>
          <h2 className="text-lg text-gray-600 mb-6">VIC Tree Permit Intake System</h2>
          
          <div className="bg-primary-50 border border-primary-200 rounded-lg p-4 mb-6 text-left">
            <h3 className="font-semibold text-primary-800 mb-2">First Time Setup</h3>
            <ul className="text-sm text-primary-700 space-y-1">
              <li>• Create a 4-digit PIN to secure this application</li>
              <li>• You'll receive a recovery key - save it securely</li>
              <li>• All data is stored locally on this USB drive</li>
              <li>• Victoria, Australia addresses only</li>
            </ul>
          </div>

          <button
            onClick={() => {
              setStep('pin')
              setTimeout(() => pinRefs[0].current?.focus(), 100)
            }}
            className="btn-primary w-full py-3 text-lg"
          >
            Get Started
          </button>
        </div>
      </div>
    )
  }

  if (step === 'pin') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 to-gray-800 p-4">
        <div className="card max-w-md w-full text-center">
          <Shield className="w-16 h-16 text-primary-600 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Create Your PIN</h2>
          <p className="text-gray-600 mb-6">Enter a 4-digit PIN to secure the application</p>

          <div className="flex justify-center gap-3 mb-6">
            {pin.map((digit, i) => (
              <input
                key={i}
                ref={pinRefs[i]}
                type="password"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={(e) => handlePinChange(i, e.target.value)}
                onKeyDown={(e) => handleKeyDown(i, e)}
                className="pin-input"
              />
            ))}
          </div>

          {error && <p className="text-red-600 text-sm mb-4">{error}</p>}

          <button
            onClick={handleSetPin}
            disabled={pin.some(d => d === '')}
            className="btn-primary w-full"
          >
            Continue
          </button>
        </div>
      </div>
    )
  }

  if (step === 'confirm') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 to-gray-800 p-4">
        <div className="card max-w-md w-full text-center">
          <Shield className="w-16 h-16 text-primary-600 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Confirm Your PIN</h2>
          <p className="text-gray-600 mb-6">Enter your PIN again to confirm</p>

          <div className="flex justify-center gap-3 mb-6">
            {confirmPin.map((digit, i) => (
              <input
                key={i}
                ref={confirmRefs[i]}
                type="password"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={(e) => handlePinChange(i, e.target.value, true)}
                onKeyDown={(e) => handleKeyDown(i, e, true)}
                className="pin-input"
              />
            ))}
          </div>

          {error && <p className="text-red-600 text-sm mb-4">{error}</p>}

          <div className="flex gap-3">
            <button
              onClick={() => {
                setStep('pin')
                setConfirmPin(['', '', '', ''])
              }}
              className="btn-secondary flex-1"
            >
              Back
            </button>
            <button
              onClick={handleConfirmPin}
              disabled={confirmPin.some(d => d === '')}
              className="btn-primary flex-1"
            >
              Create PIN
            </button>
          </div>
        </div>
      </div>
    )
  }

  if (step === 'recovery') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 to-gray-800 p-4">
        <div className="card max-w-lg w-full text-center">
          <div className="bg-amber-100 border border-amber-300 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
            <AlertTriangle className="w-8 h-8 text-amber-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Save Your Recovery Key</h2>
          <p className="text-gray-600 mb-6">
            This key allows you to reset your PIN if forgotten.<br />
            <strong className="text-red-600">It will only be shown once!</strong>
          </p>

          <div className="bg-gray-100 rounded-lg p-4 mb-4">
            <code className="text-lg font-mono font-bold tracking-wider break-all">
              {recoveryKey}
            </code>
          </div>

          <button
            onClick={handleCopy}
            className="btn-secondary w-full mb-6 flex items-center justify-center gap-2"
          >
            {copied ? (
              <>
                <Check className="w-5 h-5" />
                Copied!
              </>
            ) : (
              <>
                <Copy className="w-5 h-5" />
                Copy to Clipboard
              </>
            )}
          </button>

          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6 text-left">
            <p className="text-sm text-red-700">
              <strong>Important:</strong> Store this recovery key in a secure location. 
              Without it, you will not be able to reset your PIN if forgotten.
            </p>
          </div>

          <button
            onClick={onComplete}
            className="btn-primary w-full py-3"
          >
            I've Saved My Recovery Key
          </button>
        </div>
      </div>
    )
  }

  return null
}
