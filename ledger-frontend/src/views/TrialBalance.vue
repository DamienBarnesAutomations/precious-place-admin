<script setup>
import { ref, computed, onMounted } from 'vue'
import { Scale, RefreshCw, Loader2, CheckCircle, AlertCircle, ShieldCheck, FileCheck } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const loading = ref(false)
const error = ref(null)
const rows = ref([])

const fetchTrialBalance = async () => {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(import.meta.env.VITE_GET_TRIAL_BALANCE_WEBHOOK)
    if (!res.ok) throw new Error(`HTTP_RECONCILIATION_ERROR: ${res.status}`)
    const data = await res.json()
    rows.value = Array.isArray(data) ? data : []
  } catch (e) {
    error.value = 'Failed to load ledger integrity data'
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
  return val > 0 ? val.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '—'
}

onMounted(fetchTrialBalance)

const refresh = () => {
  fetchTrialBalance()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6 animate-fade-in">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-6">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <FileCheck class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Integrity Verification</span>
        </div>
        <h1 class="text-3xl font-black text-text tracking-tighter uppercase">Trial Balance</h1>
      </div>
      
      <div class="flex items-center gap-3">
        <div 
          class="flex items-center gap-2 px-3 py-1.5 rounded border transition-all duration-500" 
          :class="isBalanced ? 'bg-success/5 border-success/30 text-success' : 'bg-danger/5 border-danger/30 text-danger'"
        >
          <div :class="['p-0.5 rounded-full', isBalanced ? 'bg-success/20' : 'bg-danger/20']">
            <ShieldCheck v-if="isBalanced" class="w-3.5 h-3.5" />
            <AlertCircle v-else class="w-3.5 h-3.5" />
          </div>
          <span class="text-[11px] font-black uppercase tracking-widest">
            {{ isBalanced ? 'Integrity Certified' : 'Variance Detected' }}
          </span>
        </div>
        <button @click="refresh" class="btn btn-outline h-9 px-4">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">Run Analysis</span>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-24 gap-4 bg-background/20 border-dashed">
      <Loader2 class="w-10 h-10 text-primary animate-spin" />
      <p class="text-[10px] font-black text-muted uppercase tracking-[0.3em]">Reconciling Accounts...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card bg-danger/5 border-danger/20 p-6 flex items-center gap-4">
      <AlertCircle class="w-5 h-5 text-danger" />
      <span class="text-[11px] font-black text-danger uppercase tracking-widest">{{ error }}</span>
    </div>

    <!-- Data Table -->
    <div v-else class="space-y-4">
      <div class="table-container shadow-2xl border-border overflow-hidden">
        <table class="table">
          <thead>
            <tr>
              <th>Account Specification</th>
              <th class="text-right w-48">Debit Balance ($)</th>
              <th class="text-right w-48">Credit Balance ($)</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border/30">
            <tr v-for="row in computedRows" :key="row.account_id" class="group hover:bg-primary/5 transition-colors">
              <td>
                <div class="flex items-center gap-3">
                  <span class="px-1.5 py-0.5 bg-background border border-border text-[10px] font-black text-primary rounded font-mono uppercase tracking-tight group-hover:border-primary/30 transition-colors">
                    {{ row.code }}
                  </span>
                  <span class="text-[13px] font-bold text-text-secondary group-hover:text-text transition-colors uppercase tracking-tight">
                    {{ row.name }}
                  </span>
                </div>
              </td>
              <td class="text-right">
                <span class="font-mono text-[13px] font-black text-success">{{ fmt(row.dr_balance) }}</span>
              </td>
              <td class="text-right">
                <span class="font-mono text-[13px] font-black text-danger">{{ fmt(row.cr_balance) }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Footer Totals -->
      <div class="card p-0 overflow-hidden border-border bg-background/50 shadow-lg">
        <div class="flex items-center justify-between px-8 py-6">
          <div class="space-y-1">
            <span class="text-[10px] font-black text-muted uppercase tracking-[0.3em] block">Ledger Status</span>
            <div class="flex items-center gap-2">
              <div :class="['w-2 h-2 rounded-full', isBalanced ? 'bg-success shadow-glow-success' : 'bg-danger shadow-glow-danger animate-pulse']"></div>
              <span :class="['text-xs font-black uppercase tracking-widest', isBalanced ? 'text-success' : 'text-danger']">
                {{ isBalanced ? 'ACCOUNTS_SYNCHRONIZED' : 'VARIANCE_ERROR' }}
              </span>
            </div>
          </div>
          
          <div class="flex items-center gap-12">
            <div class="text-right">
              <p class="text-[9px] font-black text-muted-dark uppercase tracking-widest mb-1">Total Adjusted Debit</p>
              <div class="relative inline-block">
                <p class="text-2xl font-black font-mono text-text tracking-tighter">${{ totalDebit.toFixed(2) }}</p>
                <div class="absolute -bottom-1 left-0 right-0 h-[3px] border-b border-t border-border/50"></div>
              </div>
            </div>
            <div class="text-right">
              <p class="text-[9px] font-black text-muted-dark uppercase tracking-widest mb-1">Total Adjusted Credit</p>
              <div class="relative inline-block">
                <p class="text-2xl font-black font-mono text-text tracking-tighter">${{ totalCredit.toFixed(2) }}</p>
                <div class="absolute -bottom-1 left-0 right-0 h-[3px] border-b border-t border-border/50"></div>
              </div>
            </div>
          </div>
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
