<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Profit & Loss</h1>
        <p class="text-muted mt-1">Income Statement for Current Fiscal Year</p>
      </div>
      <button @click="fetchData" class="btn btn-outline">
        <RefreshCw class="w-4 h-4" />
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <template v-else>
      <!-- Revenue Section -->
      <div class="card">
        <div class="flex items-center gap-3 px-6 py-4 bg-success/10 border-b border-border">
          <TrendingUp class="w-6 h-6 text-success" />
          <h2 class="text-lg font-semibold text-text">Revenue</h2>
        </div>
        
        <div class="p-6 space-y-4">
          <div v-for="(accounts, label) in groupedData.income" :key="label">
            <div v-for="acc in accounts" :key="acc.code" class="flex justify-between py-2">
              <span class="text-text">{{ acc.name }}</span>
              <span class="font-mono text-text">{{ formatCurrency(acc.balance) }}</span>
            </div>
          </div>
          
          <div class="flex justify-between py-3 font-bold border-t border-border mt-4">
            <span class="text-success">Total Revenue</span>
            <span class="font-mono text-success text-lg">{{ formatCurrency(totalIncome) }}</span>
          </div>
        </div>
      </div>

      <!-- Gross Profit Section -->
      <div class="card bg-background border-l-4 border-l-success">
        <div class="flex justify-between py-3">
          <div>
            <p class="text-sm text-muted">Cost of Goods Sold</p>
            <p class="font-mono text-danger">({{ formatCurrency(totalCOGS) }})</p>
          </div>
          <div class="text-right">
            <p class="text-sm text-muted">Gross Profit</p>
            <p class="font-bold text-success text-xl">{{ formatCurrency(totalIncome - totalCOGS) }}</p>
          </div>
        </div>
      </div>

      <!-- Operating Expenses Section -->
      <div class="card">
        <div class="flex items-center gap-3 px-6 py-4 bg-danger/10 border-b border-border">
          <Wallet class="w-6 h-6 text-danger" />
          <h2 class="text-lg font-semibold text-text">Operating Expenses</h2>
        </div>
        
        <div class="p-6 space-y-4">
          <div v-for="(accounts, label) in groupedData.expense" :key="label">
            <template v-if="accounts[0]?.category_name !== 'cogs'">
              <h3 class="text-sm font-semibold text-muted uppercase tracking-wider mb-2">{{ label }}</h3>
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between py-2">
                <span class="text-text">{{ acc.name }}</span>
                <span class="font-mono text-text">{{ formatCurrency(acc.balance) }}</span>
              </div>
            </template>
          </div>
          
          <div class="flex justify-between py-3 font-bold border-t border-border mt-4">
            <span class="text-danger">Total Operating Expenses</span>
            <span class="font-mono text-danger text-lg">{{ formatCurrency(totalOpEx) }}</span>
          </div>
        </div>
      </div>

      <!-- Net Income -->
      <div 
        class="card"
        :class="netIncome >= 0 ? 'bg-success' : 'bg-danger'"
      >
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm opacity-80">Net Income / (Loss)</p>
            <p class="text-3xl font-bold">{{ formatCurrency(netIncome) }}</p>
          </div>
          <div class="w-16 h-16 rounded-full bg-white/20 flex items-center justify-center">
            <TrendingUp v-if="netIncome >= 0" class="w-8 h-8" />
            <TrendingDown v-else class="w-8 h-8" />
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Loader2, TrendingUp, TrendingDown, Wallet } from 'lucide-vue-next'

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

const formatCurrency = (val) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val)

onMounted(fetchData)

const refresh = () => {
  fetchData()
  emit('refresh')
}
</script>
