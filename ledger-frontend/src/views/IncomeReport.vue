<script setup>
import { ref, computed, onMounted } from 'vue'
import { DollarSign, RefreshCw, Loader2 } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)

const INCOME_WEBHOOK = import.meta.env.VITE_GET_INCOME_WEBHOOK

const groupedIncome = computed(() => {
  if (!rawEntries.value.length) return {}
  
  return rawEntries.value.reduce((acc, entry) => {
    const key = entry.category || 'Uncategorized Income'
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

async function fetchIncome() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(INCOME_WEBHOOK)
    if (!res.ok) throw new Error(`SERVER_ERROR: ${res.status}`)
    
    const data = await res.json()
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(e => e && Object.keys(e).length > 0)
    } else {
      rawEntries.value = []
    }
  } catch (err) {
    error.value = err.message
    rawEntries.value = []
  } finally {
    loading.value = false
  }
}

onMounted(fetchIncome)

const fmt = (val) => {
  const n = Number(val)
  return '$' + n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const totalIncome = computed(() => {
  return rawEntries.value.reduce((sum, e) => sum + Number(e.amount || 0), 0)
})

const refresh = () => {
  fetchIncome()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Income Report</h1>
        <p class="text-muted mt-1">Revenue breakdown by category</p>
      </div>
      <div class="flex items-center gap-3">
        <div class="px-4 py-2 rounded-lg bg-success/10 border border-success/30">
          <span class="text-sm text-muted">Total:</span>
          <span class="text-lg font-bold text-success ml-2">{{ fmt(totalIncome) }}</span>
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
    <div v-else-if="Object.keys(groupedIncome).length === 0" class="card">
      <div class="text-center py-12">
        <DollarSign class="w-16 h-16 text-muted mx-auto mb-4" />
        <h3 class="text-lg font-semibold text-text mb-2">No Income Recorded</h3>
        <p class="text-muted">Revenue will appear here once transactions are recorded</p>
      </div>
    </div>

    <!-- Income Cards -->
    <template v-else>
      <div v-for="(rows, category) in groupedIncome" :key="category" class="card p-0 overflow-hidden">
        <div class="flex items-center gap-3 px-6 py-4 bg-success/10 border-b border-border">
          <span class="px-2 py-1 bg-success text-white text-xs font-bold rounded">INC</span>
          <h3 class="font-semibold text-text">{{ category }}</h3>
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
                  {{ new Date(row.created_at).toLocaleDateString('en-GB') }}
                </td>
                <td class="text-text">{{ row.description || 'Direct Sale' }}</td>
                <td class="text-right">
                  <span class="font-mono text-success font-medium">{{ fmt(row.amount) }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </div>
</template>
