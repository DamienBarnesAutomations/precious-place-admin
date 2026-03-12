<script setup>
import { ref, computed, onMounted } from 'vue'
import { Wallet, RefreshCw, Loader2 } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)

const EXPENSE_WEBHOOK = import.meta.env.VITE_GET_EXPENSE_WEBHOOK

const groupedExpenses = computed(() => {
  if (!rawEntries.value.length) return {}
  
  return rawEntries.value.reduce((acc, entry) => {
    const key = entry.vendor || 'Operational Costs'
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

async function fetchExpenses() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(EXPENSE_WEBHOOK)
    if (!res.ok) throw new Error(`FETCH_ERROR: ${res.status}`)
    
    const data = await res.json()
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(e => e && Object.keys(e).length > 0)
    } else {
      rawEntries.value = []
    }
  } catch (err) {
    console.error('Expense Fetch Failed:', err)
    error.value = err.message
    rawEntries.value = []
  } finally {
    loading.value = false
  }
}

onMounted(fetchExpenses)

const fmt = (val) => {
  const n = Number(val)
  return '$' + n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const totalExpenses = computed(() => {
  return rawEntries.value.reduce((sum, e) => sum + Number(e.amount || 0), 0)
})

const refresh = () => {
  fetchExpenses()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Expense Report</h1>
        <p class="text-muted mt-1">Expense breakdown by vendor</p>
      </div>
      <div class="flex items-center gap-3">
        <div class="px-4 py-2 rounded-lg bg-danger/10 border border-danger/30">
          <span class="text-sm text-muted">Total:</span>
          <span class="text-lg font-bold text-danger ml-2">{{ fmt(totalExpenses) }}</span>
        </div>
        <button @click="refresh" class="btn btn-outline">
          <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': loading }" />
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <!-- Empty State -->
    <div v-else-if="Object.keys(groupedExpenses).length === 0" class="card">
      <div class="text-center py-12">
        <Wallet class="w-16 h-16 text-muted mx-auto mb-4" />
        <h3 class="text-lg font-semibold text-text mb-2">No Expenses Recorded</h3>
        <p class="text-muted">Expenses will appear here once transactions are recorded</p>
      </div>
    </div>

    <!-- Expense Cards -->
    <template v-else>
      <div v-for="(rows, vendor) in groupedExpenses" :key="vendor" class="card p-0 overflow-hidden">
        <div class="flex items-center gap-3 px-6 py-4 bg-danger/10 border-b border-border border-l-4 border-l-danger">
          <span class="px-2 py-1 bg-danger text-white text-xs font-bold rounded">EXP</span>
          <h3 class="font-semibold text-text">{{ vendor }}</h3>
        </div>

        <div class="table-container">
          <table class="table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Description</th>
                <th class="text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(row, i) in rows" :key="i">
                <td class="font-mono text-sm">
                  {{ new Date(row.entry_date).toLocaleDateString('en-GB') }}
                </td>
                <td class="text-text">{{ row.description || 'Fixed Cost' }}</td>
                <td class="text-right">
                  <span class="font-mono text-danger font-medium">({{ fmt(row.amount) }})</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </div>
</template>
