<script setup>
import { ref, computed, onMounted } from 'vue'
import { 
  Library, 
  RefreshCw, 
  Loader2,
  ArrowUpRight,
  ArrowDownRight,
  ChevronLeft,
  ChevronRight,
  BookOpenCheck,
  Search
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)
const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = ref(8)

const LEDGER_WEBHOOK = import.meta.env.VITE_GET_GENERAL_LEDGER_WEBHOOK

const groupedLedger = computed(() => {
  if (!rawEntries.value.length) return {}
  return rawEntries.value.reduce((acc, entry) => {
    const key = `${entry.account_code} · ${entry.account_name}`
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

const accountKeys = computed(() => {
  let keys = Object.keys(groupedLedger.value)
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    keys = keys.filter(k => k.toLowerCase().includes(query))
  }
  return keys
})

const paginatedAccounts = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  return accountKeys.value.slice(start, start + itemsPerPage.value)
})

const totalPages = computed(() => Math.ceil(accountKeys.value.length / itemsPerPage.value))

async function fetchLedger() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(LEDGER_WEBHOOK)
    if (!res.ok) throw new Error('DATA_RETRIEVAL_FAILURE')
    const data = await res.json()
    
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(entry => entry && Object.keys(entry).length > 0)
    } else {
      rawEntries.value = []
    }
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(fetchLedger)

const fmt = (val) => {
  const n = Number(val)
  if (isNaN(n) || n === 0) return '—'
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const getAccountBalance = (key) => {
  const entries = groupedLedger.value[key]
  return entries.reduce((sum, e) => sum + (Number(e.debit) || 0) - (Number(e.credit) || 0), 0)
}

const refresh = () => {
  fetchLedger()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6 animate-fade-in">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-6">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <BookOpenCheck class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Master Ledger</span>
        </div>
        <h1 class="text-3xl font-black text-text tracking-tighter uppercase">General Ledger</h1>
      </div>
      
      <div class="flex items-center gap-2">
        <div class="relative hidden md:block">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted" />
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="SEARCH ACCOUNTS..."
            class="input pl-9 h-9 w-48 text-[10px] font-bold uppercase tracking-widest bg-surface border-transparent focus:border-primary/30"
          />
        </div>
        <button 
          @click="refresh"
          class="btn btn-outline h-9 px-4"
        >
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">Refresh</span>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-24 gap-4 bg-background/20 border-dashed">
      <Loader2 class="w-10 h-10 text-primary animate-spin" />
      <p class="text-[10px] font-black text-muted uppercase tracking-[0.3em]">Processing Ledger Data...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card bg-danger/5 border-danger/20 p-6 flex items-center gap-4">
      <div class="w-10 h-10 rounded bg-danger/10 flex items-center justify-center">
        <Library class="w-5 h-5 text-danger" />
      </div>
      <span class="text-[11px] font-black text-danger uppercase tracking-widest">Error: {{ error }}</span>
    </div>

    <!-- Empty State -->
    <div v-else-if="accountKeys.length === 0" class="card py-24 border-dashed bg-background/20">
      <div class="text-center max-w-xs mx-auto">
        <Library class="w-12 h-12 text-muted-dark mx-auto mb-4" />
        <h3 class="text-sm font-black text-text uppercase tracking-widest mb-1">No Account Data</h3>
        <p class="text-[10px] text-muted font-bold uppercase tracking-tighter">Specify a valid account range or initialize your chart of accounts.</p>
      </div>
    </div>

    <!-- Ledger Cards Grid -->
    <template v-else>
      <div class="grid grid-cols-1 gap-6">
        <div 
          v-for="accountKey in paginatedAccounts" 
          :key="accountKey"
          class="card p-0 overflow-hidden border-border bg-surface shadow-lg group hover:border-primary/20 transition-colors"
        >
          <!-- Account Header -->
          <div class="flex items-center justify-between px-6 py-3 bg-background/50 border-b border-border">
            <div class="flex items-center gap-3">
              <span class="px-2 py-0.5 bg-primary/10 text-primary text-[11px] font-black font-mono rounded border border-primary/20">
                {{ accountKey.split(' · ')[0] }}
              </span>
              <span class="text-[12px] font-black text-text uppercase tracking-widest">
                {{ accountKey.split(' · ')[1] }}
              </span>
            </div>
            <div class="flex items-center gap-4">
              <div class="text-right">
                <span class="text-[9px] font-black text-muted uppercase tracking-widest block leading-none mb-0.5">NET BALANCE</span>
                <span :class="['font-mono font-black text-[14px] tracking-tighter', getAccountBalance(accountKey) >= 0 ? 'text-success' : 'text-danger']">
                  ${{ Math.abs(getAccountBalance(accountKey)).toLocaleString(undefined, { minimumFractionDigits: 2 }) }}
                  <span class="text-[10px] opacity-60 ml-0.5">{{ getAccountBalance(accountKey) >= 0 ? 'DR' : 'CR' }}</span>
                </span>
              </div>
            </div>
          </div>

          <!-- Entries Table -->
          <div class="table-container border-0 rounded-none">
            <table class="table">
              <thead>
                <tr>
                  <th class="w-32">Post Date</th>
                  <th class="w-32">Reference</th>
                  <th>Description</th>
                  <th class="text-right w-40">Debit</th>
                  <th class="text-right w-40">Credit</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-border/30">
                <tr 
                  v-for="(row, index) in groupedLedger[accountKey]" 
                  :key="index"
                  class="group/row hover:bg-primary/5 transition-colors"
                >
                  <td class="font-mono text-[11px] font-bold text-muted uppercase tracking-tighter">
                    {{ new Date(row.entry_date).toLocaleDateString('en-GB') }}
                  </td>
                  <td>
                    <span class="px-1.5 py-0.5 bg-background border border-border text-[9px] font-black text-muted uppercase tracking-tighter rounded">
                      #{{ row.reference || '0000' }}
                    </span>
                  </td>
                  <td class="font-bold text-text-secondary text-[12px] group-hover/row:text-text transition-colors">
                    {{ row.description || 'N/A' }}
                  </td>
                  <td class="text-right">
                    <div class="flex items-center justify-end gap-1.5 font-mono text-[13px]">
                      <span :class="['font-bold', row.debit ? 'text-success' : 'text-muted-dark']">{{ fmt(row.debit) }}</span>
                      <ArrowDownRight class="w-3 h-3 text-success opacity-30" v-if="row.debit" />
                    </div>
                  </td>
                  <td class="text-right">
                    <div class="flex items-center justify-end gap-1.5 font-mono text-[13px]">
                      <span :class="['font-bold', row.credit ? 'text-danger' : 'text-muted-dark']">{{ fmt(row.credit) }}</span>
                      <ArrowUpRight class="w-3 h-3 text-danger opacity-30" v-if="row.credit" />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Pagination -->
      <div class="flex items-center justify-between px-2 pt-4">
        <p class="text-[10px] font-black text-muted uppercase tracking-widest">
          LEDSYNC: {{ accountKeys.length }} ACCOUNTS INDEXED <span class="mx-2 text-border">|</span>
          PAGE {{ currentPage }} / {{ totalPages }}
        </p>
        <div class="flex items-center gap-1.5">
          <button 
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="btn btn-outline w-8 h-8 p-0 disabled:opacity-20"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          <button 
            @click="currentPage++"
            :disabled="currentPage >= totalPages"
            class="btn btn-outline w-8 h-8 p-0 disabled:opacity-20"
          >
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </template>
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
