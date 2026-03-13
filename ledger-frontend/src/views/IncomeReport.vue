<script setup>
import { ref, computed, onMounted } from 'vue'
import { DollarSign, RefreshCw, Loader2, TrendingUp } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)

const INCOME_WEBHOOK = import.meta.env.VITE_GET_INCOME_WEBHOOK

async function fetchIncome() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(INCOME_WEBHOOK)
    if (!res.ok) throw new Error(`API_COMMUNICATION_ERROR: ${res.status}`)
    const data = await res.json()
    rawEntries.value = Array.isArray(data) ? data.filter(e => e && Object.keys(e).length > 0) : []
  } catch (err) {
    console.error('Income Fetch Failed:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(fetchIncome)

const fmt = (val) => {
  const n = Number(val)
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const totalIncome = computed(() => rawEntries.value.reduce((sum, e) => sum + Number(e.amount || 0), 0))

const refresh = () => {
  fetchIncome()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6 pb-12">
    <!-- Header -->
    <div class="flex items-end justify-between border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">Income Audit</h1>
        <div class="flex items-center gap-2 mt-1">
          <TrendingUp class="w-3.5 h-3.5 text-success" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Revenue Realization Report</p>
        </div>
      </div>
      
      <div class="flex items-center gap-4 text-right">
        <div class="bg-emerald-50 border border-emerald-100 px-4 py-1.5 rounded">
          <p class="text-[10px] font-bold text-emerald-600 uppercase tracking-widest">Aggregate Income</p>
          <p class="font-mono text-lg font-bold text-emerald-700">${{ fmt(totalIncome) }}</p>
        </div>
        <button @click="refresh" class="btn btn-outline h-10">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="ml-1">Refresh</span>
        </button>
      </div>
    </div>

    <!-- Table -->
    <div class="card overflow-hidden shadow-sm p-0 border-slate-300">
      <div v-if="loading" class="p-24 flex flex-col items-center justify-center gap-3 bg-white">
        <Loader2 class="w-8 h-8 text-primary animate-spin" />
        <p class="text-xs font-bold text-muted uppercase tracking-widest">Auditing Revenue Streams...</p>
      </div>

      <div v-else-if="rawEntries.length === 0" class="p-24 text-center bg-white">
        <p class="text-sm font-medium text-muted">No revenue distributions recorded for this period.</p>
      </div>

      <table v-else class="w-full bg-white">
        <thead>
          <tr class="bg-slate-50 border-b border-slate-200">
            <th class="pl-6 w-48">Timestamp</th>
            <th class="w-40">Category</th>
            <th>Description</th>
            <th class="text-right pr-6 w-40">Amount</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="(row, i) in rawEntries" :key="i" class="hover:bg-slate-50/50 transition-colors">
            <td class="pl-6 py-3 font-mono text-xs text-muted-dark">
              {{ new Date(row.created_at).toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) }}
            </td>
            <td class="py-3">
              <span class="text-[10px] font-bold uppercase tracking-tight text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded border border-slate-200">
                {{ row.category || 'Revenue' }}
              </span>
            </td>
            <td class="py-3 text-sm text-text font-medium">
              {{ row.description || 'Direct Revenue Realization' }}
            </td>
            <td class="pr-6 py-3 text-right font-mono text-sm font-bold text-emerald-700 tabular-nums">
              {{ fmt(row.amount) }}
            </td>
          </tr>
        </tbody>
        <tfoot class="bg-slate-50 font-bold border-t-2 border-slate-900">
          <tr>
            <td colspan="3" class="pl-6 py-4 text-xs uppercase tracking-widest text-slate-900">Total Statement Realization</td>
            <td class="pr-6 py-4 text-right font-mono text-base text-slate-900 underline decoration-double">
              ${{ fmt(totalIncome) }}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>
