<script setup>
import { ref, computed, onMounted } from 'vue'
import { DollarSign, RefreshCw, Loader2, TrendingUp, BarChart3 } from 'lucide-vue-next'

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
    if (!res.ok) throw new Error(`API_COMMUNICATION_ERROR: ${res.status}`)
    
    const data = await res.json()
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(e => e && Object.keys(e).length > 0)
    } else {
      rawEntries.value = []
    }
  } catch (err) {
    console.error('Income Fetch Failed:', err)
    error.value = err.message
    rawEntries.value = []
  } finally {
    loading.value = false
  }
}

onMounted(fetchIncome)

const fmt = (val) => {
  const n = Number(val)
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
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
  <div class="space-y-4 animate-fade-in pb-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-3 border-b border-border pb-4">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <TrendingUp class="w-4 h-4 text-success" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Revenue Analysis</span>
        </div>
        <h1 class="text-2xl font-black text-text tracking-tighter uppercase">Income Statement</h1>
      </div>
      
      <div class="flex items-center gap-3">
        <div class="px-4 py-1.5 rounded bg-success/5 border border-success/20 text-right shadow-glow-success">
          <span class="text-[8px] font-black text-success uppercase tracking-widest block opacity-70 leading-none mb-1">Aggregate Income</span>
          <span class="text-xl font-black font-mono text-success tracking-tighter leading-none">${{ fmt(totalIncome) }}</span>
        </div>
        <button @click="refresh" class="btn btn-outline h-8 px-3">
          <RefreshCw class="w-3 h-3" :class="{ 'animate-spin': loading }" />
          <span class="text-[10px] font-black uppercase tracking-widest ml-1">Refresh</span>
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-16 gap-3 bg-background/20 border-dashed">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
      <p class="text-[9px] font-black text-muted uppercase tracking-[0.3em]">Auditing Revenue Streams...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="Object.keys(groupedIncome).length === 0" class="card py-16 border-dashed bg-background/20">
      <div class="text-center max-w-xs mx-auto">
        <BarChart3 class="w-10 h-10 text-muted-dark mx-auto mb-4 opacity-20" />
        <h3 class="text-sm font-black text-text uppercase tracking-widest mb-1">No Revenue Data</h3>
        <p class="text-[10px] text-muted font-bold uppercase tracking-tighter leading-tight">Income distributions will materialize here once transactions are reconciled.</p>
      </div>
    </div>

    <!-- Income Cards -->
    <template v-else>
      <div class="grid grid-cols-1 gap-6">
        <div v-for="(rows, category) in groupedIncome" :key="category" class="card p-0 overflow-hidden border-border bg-surface shadow-lg group hover:border-success/20 transition-colors">
          <div class="flex items-center justify-between px-5 py-2.5 bg-background/50 border-b border-border">
            <div class="flex items-center gap-3">
              <div class="w-6 h-6 rounded bg-success/10 flex items-center justify-center border border-success/20">
                <DollarSign class="w-3 h-3 text-success" />
              </div>
              <h3 class="text-[11px] font-black text-text uppercase tracking-widest">{{ category }}</h3>
            </div>
            <div class="text-right">
              <span class="text-[8px] font-black text-muted uppercase tracking-widest block leading-none mb-0.5">CAT_TOTAL</span>
              <span class="font-mono font-black text-success text-[13px] tracking-tighter">
                ${{ fmt(rows.reduce((s, r) => s + Number(r.amount), 0)) }}
              </span>
            </div>
          </div>

          <div class="table-container border-0 rounded-none">
            <table class="table">
              <thead>
                <tr>
                  <th class="w-36">Timestamp</th>
                  <th>Ledger Description</th>
                  <th class="text-right w-40">Credit ($)</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-border/20">
                <tr v-for="(row, i) in rows" :key="i" class="group/row hover:bg-success/5 transition-colors">
                  <td class="font-mono text-[10px] font-bold text-muted uppercase tracking-tighter">
                    {{ new Date(row.created_at).toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) }}
                  </td>
                  <td class="font-bold text-text-secondary text-[12px] group-hover/row:text-text transition-colors uppercase tracking-tight">
                    {{ row.description || 'Direct Revenue Realization' }}
                  </td>
                  <td class="text-right">
                    <span class="font-mono text-[12px] font-black text-success tracking-tighter">{{ fmt(row.amount) }}</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
