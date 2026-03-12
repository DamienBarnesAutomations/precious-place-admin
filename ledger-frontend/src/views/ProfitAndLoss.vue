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
  <div class="space-y-4 animate-fade-in pb-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-3 border-b border-border pb-4">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <Calculator class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Operating Statement</span>
        </div>
        <h1 class="text-2xl font-black text-text tracking-tighter uppercase">Profit & Loss</h1>
      </div>
      
      <div class="flex items-center gap-3">
        <div class="hidden sm:block text-right">
          <p class="text-[9px] font-black text-muted uppercase tracking-widest">Reporting Period</p>
          <p class="text-[10px] font-bold text-text uppercase">Current Fiscal Year</p>
        </div>
        <div class="h-6 w-[1px] bg-border mx-1 hidden sm:block"></div>
        <button @click="refresh" class="btn btn-outline h-8 px-3">
          <RefreshCw class="w-3 h-3" :class="{ 'animate-spin': loading }" />
          <span class="text-[10px] font-black uppercase tracking-widest ml-1">Generate</span>
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-16 gap-3 bg-background/20 border-dashed">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
      <p class="text-[9px] font-black text-muted uppercase tracking-[0.3em]">Calculating Margins...</p>
    </div>

    <template v-else>
      <div class="grid grid-cols-1 gap-6">
        <!-- Income Statement Table -->
        <div class="card p-0 overflow-hidden border-border bg-surface shadow-xl">
          <div class="px-6 py-3 bg-background/50 border-b border-border flex items-center justify-between">
            <h2 class="text-[10px] font-black text-text uppercase tracking-[0.2em]">Statement of Financial Performance</h2>
            <span class="text-[9px] font-bold text-muted uppercase tracking-tighter">Values in USD ($)</span>
          </div>

          <div class="p-6 space-y-6">
            <!-- Revenue Section -->
            <section class="space-y-3">
              <div class="flex items-center gap-2 border-b border-border pb-1.5">
                <TrendingUp class="w-3 h-3 text-success" />
                <h3 class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Revenue (Operating Income)</h3>
              </div>
              
              <div class="space-y-1 px-2">
                <div v-for="(accounts, label) in groupedData.income" :key="label" class="space-y-1">
                  <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group">
                    <span class="text-[12px] font-bold text-text-secondary group-hover:text-text transition-colors tracking-tight uppercase">{{ acc.name }}</span>
                    <div class="flex-1 border-b border-dotted border-border mx-3 mb-1"></div>
                    <span class="font-mono text-[12px] font-black text-text">{{ formatCurrency(acc.balance) }}</span>
                  </div>
                </div>
              </div>

              <div class="flex justify-between items-center px-4 py-2 bg-success/5 rounded border border-success/10">
                <span class="text-[10px] font-black text-success uppercase tracking-widest">Total Operating Revenue</span>
                <span class="font-mono text-base font-black text-success tracking-tighter">${{ formatCurrency(totalIncome) }}</span>
              </div>
            </section>

            <!-- COGS & Gross Profit -->
            <section class="space-y-3">
              <div class="flex items-center gap-2 border-b border-border pb-1.5">
                <FileText class="w-3 h-3 text-danger" />
                <h3 class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Cost of Sales (COGS)</h3>
              </div>
              
              <div class="px-2 flex justify-between items-end">
                <span class="text-[12px] font-bold text-text-secondary tracking-tight uppercase">Direct Material & Labor Costs</span>
                <div class="flex-1 border-b border-dotted border-border mx-3 mb-1"></div>
                <span class="font-mono text-[12px] font-black text-danger">({{ formatCurrency(totalCOGS) }})</span>
              </div>

              <div class="flex justify-between items-center px-4 py-2 border-y border-border/50 bg-background/30">
                <span class="text-[11px] font-black text-text uppercase tracking-[0.2em]">Gross Trading Margin</span>
                <span class="font-mono text-base font-black text-text tracking-tighter">${{ formatCurrency(totalIncome - totalCOGS) }}</span>
              </div>
            </section>

            <!-- Operating Expenses -->
            <section class="space-y-3">
              <div class="flex items-center gap-2 border-b border-border pb-1.5">
                <Wallet class="w-3 h-3 text-warning" />
                <h3 class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Operating Expenditures (OPEX)</h3>
              </div>
              
              <div class="space-y-3 px-2">
                <div v-for="(accounts, label) in groupedData.expense" :key="label" class="space-y-1">
                  <template v-if="accounts[0]?.category_name !== 'cogs'">
                    <h4 class="text-[8px] font-black text-muted uppercase tracking-[0.2em] mb-1.5">{{ label }}</h4>
                    <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group pl-2">
                      <span class="text-[11px] font-bold text-text-secondary group-hover:text-text transition-colors tracking-tight uppercase">{{ acc.name }}</span>
                      <div class="flex-1 border-b border-dotted border-border mx-3 mb-1"></div>
                      <span class="font-mono text-[11px] font-black text-text-secondary">{{ formatCurrency(acc.balance) }}</span>
                    </div>
                  </template>
                </div>
              </div>

              <div class="flex justify-between items-center px-4 py-2 bg-danger/5 rounded border border-danger/10 mt-2">
                <span class="text-[10px] font-black text-danger uppercase tracking-widest">Total Operating Expenses</span>
                <span class="font-mono text-sm font-black text-danger tracking-tighter">${{ formatCurrency(totalOpEx) }}</span>
              </div>
            </section>
          </div>

          <!-- Bottom Line -->
          <div 
            class="px-6 py-8 flex items-center justify-between transition-colors duration-500"
            :class="netIncome >= 0 ? 'bg-success shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]' : 'bg-danger shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]'"
          >
            <div>
              <p class="text-[9px] font-black uppercase tracking-[0.4em] opacity-70 mb-0.5">Net Comprehensive Income</p>
              <h2 class="text-3xl font-black tracking-tighter uppercase">{{ netIncome >= 0 ? 'Surplus' : 'Deficit' }}</h2>
            </div>
            <div class="text-right">
              <div class="relative inline-block">
                <p class="text-4xl font-black font-mono tracking-tighter">${{ formatCurrency(netIncome) }}</p>
                <!-- Double Underline Aesthetic -->
                <div class="absolute -bottom-1.5 left-0 right-0 h-[3px] border-b border-t border-white/30"></div>
              </div>
              <div class="flex items-center justify-end gap-2 mt-3 opacity-80">
                <component :is="netIncome >= 0 ? TrendingUp : TrendingDown" class="w-4 h-4" />
                <span class="text-[10px] font-black uppercase tracking-widest">{{ netIncome >= 0 ? 'Growth_Positive' : 'Action_Required' }}</span>
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
