import { useState, useEffect } from 'react'
import { Search, AlertTriangle, CheckCircle, Clock, Trash2, Eye, Download } from 'lucide-react'

const API_BASE = '/api'

export default function EnquiriesList({ onViewEnquiry }) {
  const [enquiries, setEnquiries] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [exporting, setExporting] = useState(false)

  useEffect(() => {
    fetchEnquiries()
  }, [])

  const fetchEnquiries = async () => {
    try {
      const res = await fetch(`${API_BASE}/enquiries`)
      const data = await res.json()
      setEnquiries(data || [])
    } catch (err) {
      console.error('Failed to fetch enquiries:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this enquiry?')) return

    try {
      const res = await fetch(`${API_BASE}/enquiry/${id}`, { method: 'DELETE' })
      const data = await res.json()
      if (data.success) {
        setEnquiries(prev => prev.filter(e => e.id !== id))
      }
    } catch (err) {
      console.error('Delete failed:', err)
    }
  }

  const handleExportAll = async () => {
    setExporting(true)
    try {
      const res = await fetch(`${API_BASE}/export-all`)
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

  const filteredEnquiries = enquiries.filter(e => {
    const searchLower = search.toLowerCase()
    return (
      e.client_name?.toLowerCase().includes(searchLower) ||
      e.email?.toLowerCase().includes(searchLower) ||
      e.tree_address?.toLowerCase().includes(searchLower) ||
      e.suburb?.toLowerCase().includes(searchLower)
    )
  })

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-AU', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <Clock className="w-8 h-8 text-gray-400 mx-auto mb-2 animate-pulse" />
          <p className="text-gray-500">Loading enquiries...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-5xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Recent Enquiries</h2>
        
        <div className="flex gap-3">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="input-field pl-10"
            />
          </div>
          
          <button
            onClick={handleExportAll}
            disabled={exporting || enquiries.length === 0}
            className="btn-secondary flex items-center gap-2 whitespace-nowrap"
          >
            <Download className="w-4 h-4" />
            Export All
          </button>
        </div>
      </div>

      {filteredEnquiries.length === 0 ? (
        <div className="card text-center py-12">
          <Clock className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-1">No enquiries found</h3>
          <p className="text-gray-500">
            {search ? 'Try adjusting your search' : 'Create your first enquiry to get started'}
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredEnquiries.map((enquiry) => (
            <div key={enquiry.id} className="card hover:shadow-md transition-shadow">
              <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-semibold text-gray-900 truncate">{enquiry.client_name}</h3>
                    {enquiry.immediate_risk && (
                      <span className="flex-shrink-0 bg-red-100 text-red-700 text-xs px-2 py-0.5 rounded-full flex items-center gap-1">
                        <AlertTriangle className="w-3 h-3" />
                        Risk
                      </span>
                    )}
                  </div>
                  
                  <p className="text-sm text-gray-600 truncate">{enquiry.tree_address}</p>
                  
                  <div className="flex flex-wrap items-center gap-3 mt-2 text-xs text-gray-500">
                    <span>{formatDate(enquiry.created_at)}</span>
                    <span className="capitalize">{enquiry.work_type || 'N/A'}</span>
                    
                    <span className={`flex items-center gap-1 ${
                      enquiry.confidence_flag?.includes('Verified') 
                        ? 'text-green-600' 
                        : 'text-amber-600'
                    }`}>
                      {enquiry.confidence_flag?.includes('Verified') ? (
                        <CheckCircle className="w-3 h-3" />
                      ) : (
                        <AlertTriangle className="w-3 h-3" />
                      )}
                      {enquiry.confidence_flag?.includes('Verified') ? 'Verified' : 'Manual'}
                    </span>
                    
                    <span className={`${
                      enquiry.sync_status === 'synced' 
                        ? 'text-green-600' 
                        : 'text-gray-400'
                    }`}>
                      {enquiry.sync_status === 'synced' ? '✓ Synced' : 'Local only'}
                    </span>
                  </div>
                </div>

                <div className="flex gap-2 sm:flex-shrink-0">
                  <button
                    onClick={() => onViewEnquiry(enquiry)}
                    className="btn-secondary flex items-center gap-1 text-sm"
                  >
                    <Eye className="w-4 h-4" />
                    View
                  </button>
                  <button
                    onClick={() => handleDelete(enquiry.id)}
                    className="btn-danger flex items-center gap-1 text-sm"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <p className="text-center text-sm text-gray-500 mt-6">
        Showing {filteredEnquiries.length} of {enquiries.length} enquiries (last 7 days)
      </p>
    </div>
  )
}
