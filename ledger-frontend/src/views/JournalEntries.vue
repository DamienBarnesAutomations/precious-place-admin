<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  FileText, PlusCircle, RefreshCw, Search, Filter, Loader2, 
  ArrowUpRight, ArrowDownRight, ChevronLeft, ChevronRight, History, Download 
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const entries = ref([])
const loading = ref(false)
const error = ref(null)
const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = ref(20) // Increased density

const JOURNAL_WEBHOOK = import.meta.env.VITE_GET_JOURNAL_ENTRIES_WEBHOOK

async function fetchEntries() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(JOURNAL_WEBHOOK)
    if (!res.ok) throw new Error('DATA_FETCH_ERROR')
    const data = await res.json()
    
    if (Array.isArray(data)) {
      entries.value = data.filter(entry => entry && Object.keys(entry).length > 0)
    } else {
      entries.value = []
    }
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(fetchEntries)

const fmt = (val) => {
  const n = Number(val)
  if (isNaN(n) || n === 0) return '—'
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const filteredEntries = computed(() => {
  if (!searchQuery.value) return entries.value
  const query = searchQuery.value.toLowerCase()
  return entries.value.filter(entry => 
    (entry.description && entry.description.toLowerCase().includes(query)) ||
    (entry.reference && entry.reference.toString().toLowerCase().includes(query))
  )
})

const paginatedEntries = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  return filteredEntries.value.slice(start, start + itemsPerPage.value)
})

const totalPages = computed(() => Math.ceil(filteredEntries.value.length / itemsPerPage.value))

const refresh = () => {
  fetchEntries()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">Journal Records</h1>
        <div class="flex items-center gap-2 mt-1">
          <History class="w-3.5 h-3.5 text-muted" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Transaction Audit Trail</p>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <button @click="refresh" class="btn btn-outline h-9 px-3">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="ml-1">Sync</span>
        </button>
        <RouterLink to="/accounting/journal/new" class="btn btn-primary h-9 px-4">
          <PlusCircle class="w-3.5 h-3.5" />
          <span class="ml-1">New Entry</span>
        </RouterLink>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-3 bg-white p-1 rounded border border-border">
      <div class="relative flex-1">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Filter by reference or description..."
          class="block w-full rounded-sm border-0 py-1.5 pl-9 text-sm text-text placeholder:text-muted focus:ring-0"
        />
      </div>
      <div class="h-4 w-px bg-border"></div>
      <button class="px-3 py-1 text-xs font-medium text-muted hover:text-text">
        Export CSV
      </button>
    </div>

    <!-- Table -->
    <div class="card overflow-hidden shadow-sm p-0">
      <div v-if="loading" class="p-12 flex flex-col items-center justify-center gap-3">
        <Loader2 class="w-8 h-8 text-primary animate-spin" />
        <p class="text-xs font-medium text-muted uppercase tracking-wider">Loading Ledger...</p>
      </div>

      <div v-else-if="entries.length === 0" class="p-12 text-center">
        <p class="text-sm font-medium text-muted">No journal records found.</p>
      </div>

      <table v-else class="w-full">
        <thead>
          <tr>
            <th class="w-32 pl-4">Date</th>
            <th class="w-24">Ref</th>
            <th>Description</th>
            <th class="text-right w-32">Debit</th>
            <th class="text-right w-32 pr-4">Credit</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border/50 bg-white">
          <tr 
            v-for="entry in paginatedEntries" 
            :key="entry.id"
            class="group hover:bg-slate-50 transition-colors"
          >
            <td class="pl-4 py-2 font-mono text-xs text-muted-dark">
              {{ new Date(entry.entry_date).toLocaleDateString('en-GB') }}
            </td>
            <td class="py-2">
              <span class="inline-block px-1.5 py-0.5 rounded bg-slate-100 text-[10px] font-mono font-medium text-slate-600 border border-slate-200">
                #{{ entry.reference || '---' }}
              </span>
            </td>
            <td class="py-2 text-sm text-text font-medium">
              {{ entry.description || 'Adjustment' }}
            </td>
            <td class="py-2 text-right font-mono text-xs tabular-nums text-text-secondary">
              {{ fmt(entry.total_debit) }}
            </td>
            <td class="py-2 pr-4 text-right font-mono text-xs tabular-nums text-text-secondary">
              {{ fmt(entry.total_credit) }}
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination Footer -->
      <div class="flex items-center justify-between px-4 py-3 bg-slate-50 border-t border-border">
        <p class="text-xs text-muted">
          Showing <span class="font-medium text-text">{{ (currentPage - 1) * itemsPerPage + 1 }}</span> to <span class="font-medium text-text">{{ Math.min(currentPage * itemsPerPage, filteredEntries.length) }}</span> of {{ filteredEntries.length }} results
        </p>
        <div class="flex gap-1">
          <button 
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="btn btn-outline px-2 py-1 h-8 w-8 disabled:opacity-30"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          <button 
            @click="currentPage++"
            :disabled="currentPage >= totalPages"
            class="btn btn-outline px-2 py-1 h-8 w-8 disabled:opacity-30"
          >
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
