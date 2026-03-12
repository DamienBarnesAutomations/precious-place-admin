<script setup>
import { ref, computed, onMounted } from 'vue'
import { 
  Library, 
  RefreshCw, 
  Loader2,
  ArrowUpRight,
  ArrowDownRight,
  ChevronLeft,
  ChevronRight
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)
const currentPage = ref(1)
const itemsPerPage = ref(10)

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

const accountKeys = computed(() => Object.keys(groupedLedger.value))

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
    if (!res.ok) throw new Error('FETCH_ERROR')
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
  return '$' + n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const refresh = () => {
  fetchLedger()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">General Ledger</h1>
        <p class="text-muted mt-1">View account transactions grouped by account</p>
      </div>
      <button 
        @click="refresh"
        class="btn btn-outline"
      >
        <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': loading }" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="card flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card bg-danger/10 border-danger/30">
      <span class="text-sm font-medium text-danger">Error: {{ error }}</span>
    </div>

    <!-- Empty State -->
    <div v-else-if="accountKeys.length === 0" class="card">
      <div class="text-center py-12">
        <Library class="w-16 h-16 text-muted mx-auto mb-4" />
        <h3 class="text-lg font-semibold text-text mb-2">No Ledger Data</h3>
        <p class="text-muted">No general ledger entries found</p>
      </div>
    </div>

    <!-- Ledger Cards -->
    <template v-else>
      <div 
        v-for="accountKey in paginatedAccounts" 
        :key="accountKey"
        class="card p-0 overflow-hidden"
      >
        <!-- Account Header -->
        <div class="flex items-center gap-3 px-6 py-4 bg-gradient-to-r from-primary/10 to-transparent border-b border-border">
          <span class="px-2 py-1 bg-primary text-white text-xs font-bold font-mono rounded">
            {{ accountKey.split(' · ')[0] }}
          </span>
          <span class="text-sm font-semibold text-text uppercase tracking-wide">
            {{ accountKey.split(' · ')[1] }}
          </span>
        </div>

        <!-- Entries Table -->
        <div class="table-container">
          <table class="table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Reference</th>
                <th>Description</th>
                <th class="text-right">Debit</th>
                <th class="text-right">Credit</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="(row, index) in groupedLedger[accountKey]" 
                :key="index"
                class="group"
              >
                <td class="font-mono text-sm">
                  {{ new Date(row.entry_date).toLocaleDateString('en-GB') }}
                </td>
                <td>
                  <span class="badge badge-muted">#{{ row.reference || '0000' }}</span>
                </td>
                <td class="font-medium" :class="row.description ? 'text-text' : 'text-muted'">
                  {{ row.description || '—' }}
                </td>
                <td class="text-right">
                  <div class="flex items-center justify-end gap-2">
                    <ArrowDownRight class="w-4 h-4 text-success" />
                    <span class="font-mono text-success">{{ fmt(row.debit) }}</span>
                  </div>
                </td>
                <td class="text-right">
                  <div class="flex items-center justify-end gap-2">
                    <ArrowUpRight class="w-4 h-4 text-danger" />
                    <span class="font-mono text-danger">{{ fmt(row.credit) }}</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div v-if="accountKeys.length > 0" class="flex items-center justify-between">
        <p class="text-sm text-muted">
          Showing {{ (currentPage - 1) * itemsPerPage + 1 }} to {{ Math.min(currentPage * itemsPerPage, accountKeys.length) }} of {{ accountKeys.length }} accounts
        </p>
        <div class="flex items-center gap-2">
          <button 
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="btn btn-outline btn-sm"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          <span class="px-3 py-1 text-sm font-medium text-text">
            {{ currentPage }} / {{ totalPages }}
          </span>
          <button 
            @click="currentPage++"
            :disabled="currentPage >= totalPages"
            class="btn btn-outline btn-sm"
          >
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.btn-sm {
  @apply px-2.5 py-1.5 text-sm;
}
</style>
