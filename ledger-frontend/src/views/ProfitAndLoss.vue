<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Loader2, TrendingUp, TrendingDown, Wallet, Calculator, FileText } from 'lucide-vue-next'

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
  <div class="space-y-6 animate-fade-in pb-12">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-6">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <Calculator class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Operating Statement</span>
        </div>
        <h1 class="text-3xl font-black text-text tracking-tighter uppercase">Profit & Loss</h1>
      </div>
      
      <div class="flex items-center gap-3">
        <div class="hidden sm:block text-right">
          <p class="text-[9px] font-black text-muted uppercase tracking-widest">Reporting Period</p>
          <p class="text-[11px] font-bold text-text uppercase">Current Fiscal Year</p>
        </div>
        <div class="h-8 w-[1px] bg-border mx-2 hidden sm:block"></div>
        <button @click="refresh" class="btn btn-outline h-9 px-4">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">Generate</span>
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-24 gap-4 bg-background/20 border-dashed">
      <Loader2 class="w-10 h-10 text-primary animate-spin" />
      <p class="text-[10px] font-black text-muted uppercase tracking-[0.3em]">Calculating Margins...</p>
    </div>

    <template v-else>
      <div class="grid grid-cols-1 gap-8">
        <!-- Income Statement Table -->
        <div class="card p-0 overflow-hidden border-border bg-surface shadow-2xl">
          <div class="px-8 py-4 bg-background/50 border-b border-border flex items-center justify-between">
            <h2 class="text-[11px] font-black text-text uppercase tracking-[0.2em]">Statement of Financial Performance</h2>
            <span class="text-[9px] font-bold text-muted uppercase tracking-tighter">Values in USD ($)</span>
          </div>

          <div class="p-8 space-y-8">
            <!-- Revenue Section -->
            <section class="space-y-4">
              <div class="flex items-center gap-2 border-b border-border pb-2">
                <TrendingUp class="w-3.5 h-3.5 text-success" />
                <h3 class="text-[11px] font-black text-muted-dark uppercase tracking-widest">Revenue (Operating Income)</h3>
              </div>
              
              <div class="space-y-1.5 px-4">
                <div v-for="(accounts, label) in groupedData.income" :key="label" class="space-y-1.5">
                  <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group">
                    <span class="text-[13px] font-bold text-text-secondary group-hover:text-text transition-colors tracking-tight uppercase">{{ acc.name }}</span>
                    <div class="flex-1 border-b border-dotted border-border mx-4 mb-1"></div>
                    <span class="font-mono text-[13px] font-black text-text">{{ formatCurrency(acc.balance) }}</span>
                  </div>
                </div>
              </div>

              <div class="flex justify-between items-center px-4 py-2 bg-success/5 rounded border border-success/10">
                <span class="text-[11px] font-black text-success uppercase tracking-widest">Total Operating Revenue</span>
                <span class="font-mono text-base font-black text-success tracking-tighter">${{ formatCurrency(totalIncome) }}</span>
              </div>
            </section>

            <!-- COGS & Gross Profit -->
            <section class="space-y-4">
              <div class="flex items-center gap-2 border-b border-border pb-2">
                <FileText class="w-3.5 h-3.5 text-danger" />
                <h3 class="text-[11px] font-black text-muted-dark uppercase tracking-widest">Cost of Sales (COGS)</h3>
              </div>
              
              <div class="px-4 flex justify-between items-end">
                <span class="text-[13px] font-bold text-text-secondary tracking-tight uppercase">Direct Material & Labor Costs</span>
                <div class="flex-1 border-b border-dotted border-border mx-4 mb-1"></div>
                <span class="font-mono text-[13px] font-black text-danger">({{ formatCurrency(totalCOGS) }})</span>
              </div>

              <div class="flex justify-between items-center px-4 py-3 border-y-2 border-border/50 bg-background/30">
                <span class="text-[12px] font-black text-text uppercase tracking-[0.2em]">Gross Trading Margin</span>
                <span class="font-mono text-lg font-black text-text tracking-tighter">${{ formatCurrency(totalIncome - totalCOGS) }}</span>
              </div>
            </section>

            <!-- Operating Expenses -->
            <section class="space-y-4">
              <div class="flex items-center gap-2 border-b border-border pb-2">
                <Wallet class="w-3.5 h-3.5 text-warning" />
                <h3 class="text-[11px] font-black text-muted-dark uppercase tracking-widest">Operating Expenditures (OPEX)</h3>
              </div>
              
              <div class="space-y-4 px-4">
                <div v-for="(accounts, label) in groupedData.expense" :key="label" class="space-y-1.5">
                  <template v-if="accounts[0]?.category_name !== 'cogs'">
                    <h4 class="text-[9px] font-black text-muted uppercase tracking-[0.2em] mb-2">{{ label }}</h4>
                    <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group pl-2">
                      <span class="text-[12px] font-bold text-text-secondary group-hover:text-text transition-colors tracking-tight uppercase">{{ acc.name }}</span>
                      <div class="flex-1 border-b border-dotted border-border mx-4 mb-1"></div>
                      <span class="font-mono text-[12px] font-black text-text-secondary">{{ formatCurrency(acc.balance) }}</span>
                    </div>
                  </template>
                </div>
              </div>

              <div class="flex justify-between items-center px-4 py-2 bg-danger/5 rounded border border-danger/10 mt-4">
                <span class="text-[11px] font-black text-danger uppercase tracking-widest">Total Operating Expenses</span>
                <span class="font-mono text-[15px] font-black text-danger tracking-tighter">${{ formatCurrency(totalOpEx) }}</span>
              </div>
            </section>
          </div>

          <!-- Bottom Line -->
          <div 
            class="px-8 py-10 flex items-center justify-between transition-colors duration-500"
            :class="netIncome >= 0 ? 'bg-success shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]' : 'bg-danger shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]'"
          >
            <div>
              <p class="text-[10px] font-black uppercase tracking-[0.4em] opacity-70 mb-1">Net Comprehensive Income</p>
              <h2 class="text-4xl font-black tracking-tighter uppercase">{{ netIncome >= 0 ? 'Surplus' : 'Deficit' }}</h2>
            </div>
            <div class="text-right">
              <div class="relative inline-block">
                <p class="text-5xl font-black font-mono tracking-tighter">${{ formatCurrency(netIncome) }}</p>
                <!-- Double Underline Aesthetic -->
                <div class="absolute -bottom-2 left-0 right-0 h-[4px] border-b-2 border-t-2 border-white/30"></div>
              </div>
              <div class="flex items-center justify-end gap-2 mt-4 opacity-80">
                <component :is="netIncome >= 0 ? TrendingUp : TrendingDown" class="w-5 h-5" />
                <span class="text-xs font-black uppercase tracking-widest">{{ netIncome >= 0 ? 'Growth_Positive' : 'Action_Required' }}</span>
              </div>
            </div>
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
