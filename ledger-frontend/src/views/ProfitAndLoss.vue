<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Loader2, Calculator } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawData = ref([])
const loading = ref(true)

const fetchData = async () => {
  loading.value = true
  try {
    const res = await fetch(import.meta.env.VITE_GET_PROFIT_LOSS_WEBHOOK)
    rawData.value = await res.json()
  } catch (e) {
    console.error("P&L Fetch Error", e)
  } finally {
    loading.value = false
  }
}

const groupedData = computed(() => {
  const groups = { income: {}, expense: {} }
  rawData.value.forEach(item => {
    if (!groups[item.type]) return
    if (!groups[item.type][item.category_label]) {
      groups[item.type][item.category_label] = []
    }
    groups[item.type][item.category_label].push(item)
  })
  return groups
})

const totalIncome = computed(() => 
  rawData.value.filter(i => i.type === 'income').reduce((s, a) => s + Number(a.balance), 0)
)

const totalCOGS = computed(() => 
  rawData.value.filter(i => i.category_name === 'cogs').reduce((s, a) => s + Number(a.balance), 0)
)

const totalOpEx = computed(() => 
  rawData.value.filter(i => i.type === 'expense' && i.category_name !== 'cogs')
               .reduce((s, a) => s + Number(a.balance), 0)
)

const netIncome = computed(() => totalIncome.value - totalCOGS.value - totalOpEx.value)

const formatCurrency = (val) => {
  const n = Number(val)
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

onMounted(fetchData)

const refresh = () => {
  fetchData()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6 pb-12">
    <!-- Header -->
    <div class="flex items-end justify-between border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">Profit & Loss</h1>
        <div class="flex items-center gap-2 mt-1">
          <Calculator class="w-3.5 h-3.5 text-muted" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Statement of Financial Performance</p>
        </div>
      </div>
      
      <div class="flex items-center gap-4 text-right">
        <div class="hidden sm:block">
          <p class="text-[10px] font-bold text-muted uppercase">Period</p>
          <p class="text-xs font-mono font-bold uppercase tracking-tight">Current Fiscal Year</p>
        </div>
        <button @click="refresh" class="btn btn-outline h-9">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="ml-1">Generate</span>
        </button>
      </div>
    </div>

    <!-- Statement Body -->
    <div class="card p-0 overflow-hidden bg-white shadow-sm border-slate-300">
      <div v-if="loading" class="p-24 flex flex-col items-center justify-center gap-3">
        <Loader2 class="w-8 h-8 text-primary animate-spin" />
        <p class="text-xs font-bold text-muted uppercase tracking-widest">Calculating Margins...</p>
      </div>

      <div v-else class="p-8 max-w-4xl mx-auto space-y-10 text-slate-900">
        <!-- REVENUE -->
        <section>
          <h3 class="text-sm font-bold uppercase border-b-2 border-slate-900 pb-1 mb-4">Revenue</h3>
          
          <div class="space-y-1 pl-4">
            <div v-for="(accounts, label) in groupedData.income" :key="label">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between text-sm">
                <span>{{ acc.name }}</span>
                <span class="font-mono">{{ formatCurrency(acc.balance) }}</span>
              </div>
            </div>
          </div>

          <div class="flex justify-between items-center bg-slate-50 px-4 py-3 border-y border-slate-200 mt-4 font-bold text-sm uppercase">
            <span>Total Operating Revenue</span>
            <span class="font-mono">${{ formatCurrency(totalIncome) }}</span>
          </div>
        </section>

        <!-- COGS -->
        <section>
          <h3 class="text-sm font-bold uppercase border-b-2 border-slate-900 pb-1 mb-4">Cost of Goods Sold</h3>
          
          <div class="space-y-1 pl-4">
            <div class="flex justify-between text-sm">
              <span>Direct Material & Labor Costs</span>
              <span class="font-mono text-danger">({{ formatCurrency(totalCOGS) }})</span>
            </div>
          </div>

          <div class="flex justify-between items-center bg-slate-50 px-4 py-3 border-y border-slate-200 mt-4 font-bold text-sm uppercase">
            <span>Gross Trading Margin</span>
            <span class="font-mono">${{ formatCurrency(totalIncome - totalCOGS) }}</span>
          </div>
        </section>

        <!-- OPERATING EXPENSES -->
        <section>
          <h3 class="text-sm font-bold uppercase border-b-2 border-slate-900 pb-1 mb-4">Operating Expenses</h3>
          
          <div class="space-y-6 pl-4">
            <div v-for="(accounts, label) in groupedData.expense" :key="label">
              <template v-if="accounts[0]?.category_name !== 'cogs'">
                <h4 class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">{{ label }}</h4>
                <div class="space-y-1 pl-2">
                  <div v-for="acc in accounts" :key="acc.code" class="flex justify-between text-sm">
                    <span>{{ acc.name }}</span>
                    <span class="font-mono">{{ formatCurrency(acc.balance) }}</span>
                  </div>
                </div>
              </template>
            </div>
          </div>

          <div class="flex justify-between items-center bg-slate-50 px-4 py-3 border-y border-slate-200 mt-6 font-bold text-sm uppercase">
            <span>Total Operating Expenses</span>
            <span class="font-mono text-danger">({{ formatCurrency(totalOpEx) }})</span>
          </div>
        </section>

        <!-- NET INCOME -->
        <div 
          class="p-6 border-2 flex items-center justify-between transition-colors"
          :class="netIncome >= 0 ? 'bg-emerald-50 border-emerald-200' : 'bg-rose-50 border-rose-200'"
        >
          <div>
            <p class="text-[10px] font-bold uppercase tracking-[0.3em] text-slate-500 mb-1">Net Comprehensive Income</p>
            <h2 class="text-2xl font-bold tracking-tighter uppercase text-slate-900">
              {{ netIncome >= 0 ? 'Surplus' : 'Deficit' }}
            </h2>
          </div>
          <div class="text-right">
            <span 
              class="font-mono text-3xl font-bold tracking-tight underline decoration-double underline-offset-8"
              :class="netIncome >= 0 ? 'text-emerald-700' : 'text-rose-700'"
            >
              ${{ formatCurrency(netIncome) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
