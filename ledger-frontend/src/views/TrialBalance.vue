<script setup>
import { ref, computed, onMounted } from 'vue'
import { Scale, RefreshCw, Loader2, CheckCircle, AlertCircle } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const loading = ref(false)
const error = ref(null)
const rows = ref([])

const fetchTrialBalance = async () => {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(import.meta.env.VITE_GET_TRIAL_BALANCE_WEBHOOK)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    rows.value = Array.isArray(data) ? data : []
  } catch (e) {
    error.value = 'Failed to load trial balance'
  } finally {
    loading.value = false
  }
}

const computedRows = computed(() =>
  rows.value.map(r => {
    const debit = Number(r.debit) || 0
    const credit = Number(r.credit) || 0
    return {
      ...r,
      dr_balance: debit > credit ? debit - credit : 0,
      cr_balance: credit > debit ? credit - debit : 0
    }
  })
)

const totalDebit = computed(() => computedRows.value.reduce((s, r) => s + r.dr_balance, 0))
const totalCredit = computed(() => computedRows.value.reduce((s, r) => s + r.cr_balance, 0))

const isBalanced = computed(() =>
  Math.abs(totalDebit.value - totalCredit.value) < 0.01 && computedRows.value.length > 0
)

const fmt = (val) => {
  return val > 0 ? '$' + val.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '—'
}

onMounted(fetchTrialBalance)

const refresh = () => {
  fetchTrialBalance()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Trial Balance</h1>
        <p class="text-muted mt-1">Verify that debits equal credits</p>
      </div>
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-2 px-3 py-1.5 rounded-full border" :class="isBalanced ? 'bg-success/10 border-success/30' : 'bg-danger/10 border-danger/30'">
          <CheckCircle v-if="isBalanced" class="w-4 h-4 text-success" />
          <AlertCircle v-else class="w-4 h-4 text-danger" />
          <span class="text-sm font-medium" :class="isBalanced ? 'text-success' : 'text-danger'">
            {{ isBalanced ? 'System Balanced' : 'Out of Balance' }}
          </span>
        </div>
        <button @click="refresh" class="btn btn-outline">
          <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': loading }" />
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="card flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card bg-danger/10 border-danger/30">
      <span class="text-sm font-medium text-danger">{{ error }}</span>
    </div>

    <!-- Data Table -->
    <div v-else class="card p-0 overflow-hidden">
      <div class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>Account</th>
              <th class="text-right">Debit Balance</th>
              <th class="text-right">Credit Balance</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in computedRows" :key="row.account_id">
              <td>
                <div class="flex items-center gap-3">
                  <span class="font-mono font-bold text-primary">{{ row.code }}</span>
                  <span class="font-medium text-text">{{ row.name }}</span>
                </div>
              </td>
              <td class="text-right">
                <span class="font-mono text-success">{{ fmt(row.dr_balance) }}</span>
              </td>
              <td class="text-right">
                <span class="font-mono text-danger">{{ fmt(row.cr_balance) }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Footer Totals -->
      <div class="flex items-center justify-between px-6 py-4 bg-background border-t border-border">
        <span class="text-sm font-semibold text-muted uppercase tracking-wider">Verified Totals</span>
        <div class="flex items-center gap-8">
          <div class="text-right">
            <p class="text-xs text-muted mb-1">Total Debit</p>
            <p class="text-xl font-bold font-mono text-success">${{ totalDebit.toFixed(2) }}</p>
          </div>
          <div class="text-right">
            <p class="text-xs text-muted mb-1">Total Credit</p>
            <p class="text-xl font-bold font-mono text-danger">${{ totalCredit.toFixed(2) }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
