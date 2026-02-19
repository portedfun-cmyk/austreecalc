import { useState, useRef, useEffect } from 'react'
import { Shield, AlertTriangle, Key } from 'lucide-react'

const API_BASE = '/api'

export default function PinOverlay({ onSuccess }) {
  const [pin, setPin] = useState(['', '', '', ''])
  const [error, setError] = useState('')
  const [attemptsLeft, setAttemptsLeft] = useState(5)
  const [lockout, setLockout] = useState(0)
  const [shake, setShake] = useState(false)
  const [showRecovery, setShowRecovery] = useState(false)
  const [recoveryKey, setRecoveryKey] = useState('')
  const [newPin, setNewPin] = useState(['', '', '', ''])
  const inputRefs = [useRef(), useRef(), useRef(), useRef()]
  const newPinRefs = [useRef(), useRef(), useRef(), useRef()]

  useEffect(() => {
    inputRefs[0].current?.focus()
  }, [])

  useEffect(() => {
    if (lockout > 0) {
      const timer = setInterval(() => {
        setLockout(prev => Math.max(0, prev - 1))
      }, 1000)
      return () => clearInterval(timer)
    }
  }, [lockout])

  const handlePinChange = (index, value) => {
    if (!/^\d*$/.test(value)) return
    
    const newPinArr = [...pin]
    newPinArr[index] = value.slice(-1)
    setPin(newPinArr)
    setError('')

    if (value && index < 3) {
      inputRefs[index + 1].current?.focus()
    }

    if (newPinArr.every(d => d !== '') && newPinArr.join('').length === 4) {
      verifyPin(newPinArr.join(''))
    }
  }

  const handleKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !pin[index] && index > 0) {
      inputRefs[index - 1].current?.focus()
    }
  }

  const verifyPin = async (pinCode) => {
    try {
      const res = await fetch(`${API_BASE}/verify-pin`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin: pinCode })
      })
      const data = await res.json()

      if (data.success) {
        onSuccess()
      } else if (data.lockout) {
        setLockout(data.lockout)
        setError('Too many failed attempts')
        setPin(['', '', '', ''])
        setShake(true)
        setTimeout(() => setShake(false), 300)
      } else {
        setAttemptsLeft(data.attempts || attemptsLeft - 1)
        setError(data.error || 'Invalid PIN')
        setPin(['', '', '', ''])
        inputRefs[0].current?.focus()
        setShake(true)
        setTimeout(() => setShake(false), 300)
      }
    } catch (err) {
      setError('Connection error')
    }
  }

  const handleNewPinChange = (index, value) => {
    if (!/^\d*$/.test(value)) return
    
    const arr = [...newPin]
    arr[index] = value.slice(-1)
    setNewPin(arr)

    if (value && index < 3) {
      newPinRefs[index + 1].current?.focus()
    }
  }

  const handleRecovery = async () => {
    const pinCode = newPin.join('')
    if (pinCode.length !== 4) {
      setError('Enter a 4-digit PIN')
      return
    }

    try {
      const res = await fetch(`${API_BASE}/recovery`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recovery_key: recoveryKey.toUpperCase(), new_pin: pinCode })
      })
      const data = await res.json()

      if (data.success) {
        setShowRecovery(false)
        setPin(['', '', '', ''])
        setError('')
        inputRefs[0].current?.focus()
      } else if (data.lockout) {
        setLockout(data.lockout)
        setError('Recovery locked. Please wait.')
      } else {
        setError(data.error || 'Invalid recovery key')
      }
    } catch (err) {
      setError('Connection error')
    }
  }

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  if (showRecovery) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 to-gray-800 p-4">
        <div className="card max-w-md w-full text-center">
          <Key className="w-16 h-16 text-primary-600 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">PIN Recovery</h2>
          <p className="text-gray-600 mb-6">Enter your recovery key to reset your PIN</p>

          <div className="space-y-4">
            <input
              type="text"
              placeholder="Recovery Key (32 characters)"
              value={recoveryKey}
              onChange={(e) => setRecoveryKey(e.target.value.toUpperCase())}
              className="input-field font-mono text-center tracking-wider"
              maxLength={32}
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">New PIN</label>
              <div className="flex justify-center gap-3">
                {newPin.map((digit, i) => (
                  <input
                    key={i}
                    ref={newPinRefs[i]}
                    type="password"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleNewPinChange(i, e.target.value)}
                    className="pin-input"
                  />
                ))}
              </div>
            </div>

            {error && (
              <p className="text-red-600 text-sm">{error}</p>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setShowRecovery(false)}
                className="btn-secondary flex-1"
              >
                Cancel
              </button>
              <button
                onClick={handleRecovery}
                disabled={lockout > 0}
                className="btn-primary flex-1"
              >
                {lockout > 0 ? formatTime(lockout) : 'Reset PIN'}
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 to-gray-800 p-4">
      <div className={`card max-w-md w-full text-center ${shake ? 'shake' : ''}`}>
        <Shield className="w-16 h-16 text-primary-600 mx-auto mb-4" />
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Bayside Tree Works</h2>
        <p className="text-gray-600 mb-6">Enter your 4-digit PIN to continue</p>

        {lockout > 0 ? (
          <div className="space-y-4">
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <AlertTriangle className="w-8 h-8 text-red-500 mx-auto mb-2" />
              <p className="text-red-700 font-medium">Account Locked</p>
              <p className="text-red-600 text-sm">Try again in {formatTime(lockout)}</p>
            </div>
            <button
              onClick={() => setShowRecovery(true)}
              className="text-primary-600 hover:text-primary-700 text-sm font-medium"
            >
              Use Recovery Key
            </button>
          </div>
        ) : (
          <>
            <div className="flex justify-center gap-3 mb-6">
              {pin.map((digit, i) => (
                <input
                  key={i}
                  ref={inputRefs[i]}
                  type="password"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handlePinChange(i, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(i, e)}
                  className="pin-input"
                  autoComplete="off"
                />
              ))}
            </div>

            {error && (
              <div className="mb-4">
                <p className="text-red-600 text-sm">{error}</p>
                {attemptsLeft < 5 && (
                  <p className="text-gray-500 text-xs mt-1">{attemptsLeft} attempts remaining</p>
                )}
              </div>
            )}

            <button
              onClick={() => setShowRecovery(true)}
              className="text-primary-600 hover:text-primary-700 text-sm font-medium"
            >
              Forgot PIN?
            </button>
          </>
        )}
      </div>
    </div>
  )
}
