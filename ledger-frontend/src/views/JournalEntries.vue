<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  FileText, 
  PlusCircle, 
  RefreshCw, 
  Search,
  Filter,
  Loader2,
  ArrowUpRight,
  ArrowDownRight,
  ChevronLeft,
  ChevronRight,
  History,
  Download
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const entries = ref([])
const loading = ref(false)
const error = ref(null)
const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = ref(15)

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
  <div class="space-y-6 animate-fade-in">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-6">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <History class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Transaction Audit</span>
        </div>
        <h1 class="text-3xl font-black text-text tracking-tighter uppercase">Journal Records</h1>
      </div>
      
      <div class="flex items-center gap-2">
        <button @click="refresh" class="btn btn-outline h-9 px-4">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">Re-Sync</span>
        </button>
        <RouterLink to="/accounting/journal/new" class="btn btn-primary h-9 px-4">
          <PlusCircle class="w-3.5 h-3.5" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">New Entry</span>
        </RouterLink>
      </div>
    </div>

    <!-- Filters & Search -->
    <div class="flex flex-col sm:flex-row items-center gap-4 bg-surface/50 p-2 rounded-lg border border-border">
      <div class="relative flex-1 group">
        <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted group-focus-within:text-primary transition-colors" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="FILTER BY DESCRIPTION OR REFERENCE..."
          class="input pl-10 h-10 bg-background/50 border-transparent hover:border-border focus:bg-background uppercase font-bold tracking-tight text-xs"
        />
      </div>
      <div class="flex items-center gap-2">
        <button class="btn btn-outline h-10 px-4 group">
          <Filter class="w-3.5 h-3.5 text-muted group-hover:text-text" />
          <span class="text-[10px] font-black uppercase tracking-widest ml-1">Parameters</span>
        </button>
        <button class="btn btn-outline h-10 px-3 hover:bg-primary/5 hover:border-primary/30 group">
          <Download class="w-3.5 h-3.5 text-muted group-hover:text-primary" />
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-24 gap-4 bg-background/20 border-dashed">
      <div class="relative">
        <Loader2 class="w-10 h-10 text-primary animate-spin" />
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="w-1.5 h-1.5 bg-primary rounded-full animate-pulse"></div>
        </div>
      </div>
      <p class="text-[10px] font-black text-muted uppercase tracking-[0.3em]">Querying Ledger...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card bg-danger/5 border-danger/20 flex items-center gap-4 p-6">
      <div class="w-10 h-10 rounded bg-danger/10 flex items-center justify-center flex-shrink-0">
        <AlertCircle class="w-5 h-5 text-danger" />
      </div>
      <div>
        <p class="text-[11px] font-black text-danger uppercase tracking-widest">Data Synchronization Error</p>
        <p class="text-xs text-muted-dark font-medium mt-0.5">{{ error }}</p>
      </div>
      <button @click="refresh" class="btn btn-outline btn-sm ml-auto border-danger/20 text-danger hover:bg-danger/10 uppercase font-black text-[9px]">Retry Request</button>
    </div>

    <!-- Empty State -->
    <div v-else-if="entries.length === 0" class="card py-24 border-dashed bg-background/20">
      <div class="text-center max-w-xs mx-auto">
        <div class="w-16 h-16 bg-muted/5 rounded-full flex items-center justify-center mx-auto mb-6">
          <FileText class="w-8 h-8 text-muted-dark" />
        </div>
        <h3 class="text-sm font-black text-text uppercase tracking-widest mb-2">Zero Records Found</h3>
        <p class="text-[11px] text-muted-dark font-bold uppercase tracking-tighter leading-tight mb-8">No journal entries exist within the specified audit period.</p>
        <RouterLink to="/accounting/journal/new" class="btn btn-primary w-full">
          <PlusCircle class="w-4 h-4" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">Initialize Ledger</span>
        </RouterLink>
      </div>
    </div>

    <!-- Data Table -->
    <div v-else class="space-y-4">
      <div class="table-container shadow-2xl border-border overflow-hidden">
        <table class="table">
          <thead>
            <tr>
              <th class="w-32">Post Date</th>
              <th class="w-32">Reference</th>
              <th>Ledger Memo</th>
              <th class="text-right w-40">Debit ($)</th>
              <th class="text-right w-40">Credit ($)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border/30">
            <tr 
              v-for="entry in paginatedEntries" 
              :key="entry.id"
              class="group hover:bg-primary/5 transition-colors"
            >
              <td class="font-mono text-[12px] font-bold text-muted uppercase tracking-tighter">
                {{ new Date(entry.entry_date).toLocaleDateString('en-GB') }}
              </td>
              <td class="px-2">
                <span class="inline-block px-2 py-0.5 bg-background border border-border text-[10px] font-black text-text-secondary rounded font-mono uppercase tracking-tight">
                  #{{ entry.reference || '0000' }}
                </span>
              </td>
              <td class="font-bold text-text-secondary text-[13px] group-hover:text-text transition-colors">
                {{ entry.description || 'N/A' }}
              </td>
              <td class="text-right">
                <div class="flex items-center justify-end gap-1.5 font-mono text-sm">
                  <span class="text-success font-black">{{ fmt(entry.total_debit) }}</span>
                  <ArrowDownRight class="w-3 h-3 text-success opacity-40 group-hover:opacity-100 transition-opacity" />
                </div>
              </td>
              <td class="text-right">
                <div class="flex items-center justify-end gap-1.5 font-mono text-sm">
                  <span class="text-danger font-black">{{ fmt(entry.total_credit) }}</span>
                  <ArrowUpRight class="w-3 h-3 text-danger opacity-40 group-hover:opacity-100 transition-opacity" />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div class="flex items-center justify-between px-2">
        <div class="flex items-center gap-4">
          <p class="text-[10px] font-black text-muted uppercase tracking-widest">
            Page {{ currentPage }} of {{ totalPages }} <span class="mx-2 text-border">|</span> 
            Showing {{ (currentPage - 1) * itemsPerPage + 1 }} - {{ Math.min(currentPage * itemsPerPage, filteredEntries.length) }}
          </p>
        </div>
        <div class="flex items-center gap-1.5">
          <button 
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="btn btn-outline w-8 h-8 p-0 disabled:opacity-20"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          
          <div class="flex items-center gap-1 mx-2">
            <span v-for="p in Math.min(totalPages, 5)" :key="p" 
              class="w-1.5 h-1.5 rounded-full transition-all duration-300"
              :class="p === currentPage ? 'bg-primary w-4' : 'bg-muted/30'"
            ></span>
          </div>

          <button 
            @click="currentPage++"
            :disabled="currentPage >= totalPages"
            class="btn btn-outline w-8 h-8 p-0 disabled:opacity-20"
          >
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.4s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>

<style scoped>
.btn-sm {
  @apply px-2.5 py-1.5 text-sm;
}
</style>
