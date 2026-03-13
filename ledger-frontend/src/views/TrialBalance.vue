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
  if (val === 0) return '-'
  return val.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
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
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">Trial Balance</h1>
        <div class="flex items-center gap-2 mt-1">
          <FileCheck class="w-3.5 h-3.5 text-muted" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Integrity Verification</p>
        </div>
      </div>
      
      <div class="flex items-center gap-2">
        <button @click="refresh" class="btn btn-outline h-9 px-3">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="ml-1">Sync</span>
        </button>
      </div>
    </div>

    <!-- Summary Banner -->
    <div 
      class="card p-4 border-l-4 transition-colors"
      :class="isBalanced ? 'border-l-success bg-emerald-50' : 'border-l-danger bg-rose-50'"
    >
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div :class="['p-1.5 rounded-full bg-white border shadow-sm', isBalanced ? 'text-success border-success/20' : 'text-danger border-danger/20']">
            <ShieldCheck v-if="isBalanced" class="w-5 h-5" />
            <AlertCircle v-else class="w-5 h-5" />
          </div>
          <div>
            <h3 class="text-sm font-bold text-slate-800 uppercase tracking-tight">
              {{ isBalanced ? 'Ledger Reconciled' : 'Variance Detected' }}
            </h3>
            <p class="text-[10px] font-bold text-slate-500 uppercase tracking-widest">
              {{ isBalanced ? 'All accounts are in technical alignment' : 'Correcting entries may be required' }}
            </p>
          </div>
        </div>
        
        <div class="flex items-center gap-6">
           <div class="text-right">
             <span class="block text-[10px] font-bold text-slate-400 uppercase">Debit Total</span>
             <span class="font-mono text-sm font-bold text-slate-700">${{ totalDebit.toLocaleString(undefined, {minimumFractionDigits: 2}) }}</span>
           </div>
           <div class="text-right">
             <span class="block text-[10px] font-bold text-slate-400 uppercase">Credit Total</span>
             <span class="font-mono text-sm font-bold text-slate-700">${{ totalCredit.toLocaleString(undefined, {minimumFractionDigits: 2}) }}</span>
           </div>
        </div>
      </div>
    </div>

    <!-- Data Table -->
    <div class="card overflow-hidden shadow-sm p-0">
      <div v-if="loading" class="p-12 flex flex-col items-center justify-center gap-3">
        <Loader2 class="w-8 h-8 text-primary animate-spin" />
        <p class="text-xs font-bold text-muted uppercase tracking-wider">Verifying Balances...</p>
      </div>

      <table v-else class="w-full">
        <thead>
          <tr>
            <th class="pl-4">Account Specification</th>
            <th class="text-right w-40">Debit</th>
            <th class="text-right w-40 pr-4">Credit</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border/50 bg-white">
          <tr v-for="row in computedRows" :key="row.account_id" class="hover:bg-slate-50 transition-colors">
            <td class="pl-4 py-2">
              <div class="flex items-center gap-3">
                <span class="font-mono text-[10px] font-bold text-slate-500 bg-slate-100 px-1 py-0.5 rounded border border-slate-200">
                  {{ row.code }}
                </span>
                <span class="text-sm font-medium text-text-secondary uppercase tracking-tight">
                  {{ row.name }}
                </span>
              </div>
            </td>
            <td class="py-2 text-right font-mono text-xs tabular-nums text-text">
              {{ fmt(row.dr_balance) }}
            </td>
            <td class="py-2 pr-4 text-right font-mono text-xs tabular-nums text-text">
              {{ fmt(row.cr_balance) }}
            </td>
          </tr>
        </tbody>
        <tfoot class="bg-slate-50 font-bold border-t border-border">
          <tr>
            <td class="pl-4 py-3 text-xs uppercase tracking-widest text-muted">Verification Totals</td>
            <td class="py-3 text-right font-mono text-sm text-slate-700 underline decoration-double">
              {{ totalDebit.toLocaleString(undefined, {minimumFractionDigits: 2}) }}
            </td>
            <td class="py-3 pr-4 text-right font-mono text-sm text-slate-700 underline decoration-double">
              {{ totalCredit.toLocaleString(undefined, {minimumFractionDigits: 2}) }}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>
