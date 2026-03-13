<script setup>
import { ref, computed, onMounted } from 'vue'
import { 
  Library, RefreshCw, Loader2, ArrowUpRight, ArrowDownRight, 
  ChevronLeft, ChevronRight, BookOpenCheck, Search 
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)
const searchQuery = ref('')

const LEDGER_WEBHOOK = import.meta.env.VITE_GET_GENERAL_LEDGER_WEBHOOK

const groupedLedger = computed(() => {
  if (!rawEntries.value.length) return {}
  // Sort entries by date descending within accounts
  return rawEntries.value.reduce((acc, entry) => {
    const key = `${entry.account_code} · ${entry.account_name}`
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

const accountKeys = computed(() => {
  let keys = Object.keys(groupedLedger.value).sort()
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    keys = keys.filter(k => k.toLowerCase().includes(query))
  }
  return keys
})

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
  if (isNaN(n) || n === 0) return '-'
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const getAccountBalance = (key) => {
  const entries = groupedLedger.value[key]
  // Simplified balance calculation - implies Asset/Expense normal debit, others normal credit
  // For display only, using raw diff
  return entries.reduce((sum, e) => sum + (Number(e.debit) || 0) - (Number(e.credit) || 0), 0)
}

const refresh = () => {
  fetchLedger()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6 pb-12">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">General Ledger</h1>
        <div class="flex items-center gap-2 mt-1">
          <BookOpenCheck class="w-3.5 h-3.5 text-muted" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Master Account Records</p>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <div class="relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted" />
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="Search Accounts..."
            class="input h-9 pl-9 text-xs"
          />
        </div>
        <button @click="refresh" class="btn btn-outline h-9 px-3">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="ml-1">Sync</span>
        </button>
      </div>
    </div>

    <!-- Content -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-24 gap-3 border border-dashed border-border rounded bg-slate-50/50">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
      <p class="text-xs font-bold text-muted uppercase tracking-wider">Compiling Ledger...</p>
    </div>

    <div v-else-if="accountKeys.length === 0" class="py-24 text-center border border-dashed border-border rounded bg-slate-50/50">
      <Library class="w-10 h-10 text-muted/30 mx-auto mb-3" />
      <p class="text-sm font-medium text-muted">No accounts match your query.</p>
    </div>

    <div v-else class="space-y-8">
      <!-- Account Block -->
      <div 
        v-for="accountKey in accountKeys" 
        :key="accountKey"
        class="border border-border rounded-lg overflow-hidden shadow-sm bg-white"
      >
        <!-- Sticky Account Header -->
        <div class="bg-slate-100 border-b border-border px-4 py-3 flex items-center justify-between sticky top-0 z-10">
          <div class="flex items-center gap-3">
            <span class="font-mono text-xs font-bold text-slate-700 bg-white border border-slate-200 px-1.5 py-0.5 rounded">
              {{ accountKey.split(' · ')[0] }}
            </span>
            <h3 class="text-sm font-bold text-slate-800 uppercase tracking-tight">
              {{ accountKey.split(' · ')[1] }}
            </h3>
          </div>
          <div class="text-right">
            <span class="text-[10px] font-bold text-muted uppercase tracking-wider mr-2">Net Balance</span>
            <span 
              class="font-mono text-sm font-bold tracking-tight"
              :class="getAccountBalance(accountKey) >= 0 ? 'text-text' : 'text-danger'"
            >
              {{ fmt(Math.abs(getAccountBalance(accountKey))) }}
              <span class="text-xs text-muted ml-0.5">{{ getAccountBalance(accountKey) >= 0 ? 'DR' : 'CR' }}</span>
            </span>
          </div>
        </div>

        <!-- Transactions Table -->
        <table class="w-full">
          <thead>
            <tr class="bg-slate-50 border-b border-border">
              <th class="w-32 pl-4 py-2 font-medium text-muted-dark uppercase text-[10px]">Date</th>
              <th class="w-24 py-2 font-medium text-muted-dark uppercase text-[10px]">Ref</th>
              <th class="py-2 font-medium text-muted-dark uppercase text-[10px]">Memo</th>
              <th class="text-right w-32 py-2 font-medium text-muted-dark uppercase text-[10px]">Debit</th>
              <th class="text-right w-32 pr-4 py-2 font-medium text-muted-dark uppercase text-[10px]">Credit</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border/50">
            <tr 
              v-for="(row, index) in groupedLedger[accountKey]" 
              :key="index"
              class="hover:bg-slate-50 transition-colors"
            >
              <td class="pl-4 py-2 font-mono text-xs text-muted-dark whitespace-nowrap">
                {{ new Date(row.entry_date).toLocaleDateString('en-GB') }}
              </td>
              <td class="py-2">
                <span class="text-[10px] font-mono text-slate-500">
                  #{{ row.reference || '---' }}
                </span>
              </td>
              <td class="py-2 text-xs font-medium text-text-secondary truncate max-w-xs">
                {{ row.description || 'Adjustment' }}
              </td>
              <td class="py-2 text-right font-mono text-xs text-slate-600">
                <span v-if="row.debit" class="text-text font-medium">{{ fmt(row.debit) }}</span>
                <span v-else class="text-slate-300">-</span>
              </td>
              <td class="pr-4 py-2 text-right font-mono text-xs text-slate-600">
                <span v-if="row.credit" class="text-text font-medium">{{ fmt(row.credit) }}</span>
                <span v-else class="text-slate-300">-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
