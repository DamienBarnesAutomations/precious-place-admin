<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Balance Sheet</h1>
        <p class="text-muted mt-1">As of {{ new Date().toLocaleDateString() }}</p>
      </div>
      <button @click="fetchData" class="btn btn-outline">
        <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': loading }" />
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <template v-else>
      <!-- Assets Section -->
      <div class="card">
        <div class="flex items-center gap-3 px-6 py-4 bg-success/10 border-b border-border">
          <Building2 class="w-6 h-6 text-success" />
          <h2 class="text-lg font-semibold text-text">Assets</h2>
        </div>
        
        <div class="p-6 space-y-6">
          <div v-for="(accounts, category) in groupedData.asset" :key="category">
            <h3 class="text-sm font-semibold text-muted uppercase tracking-wider mb-3">{{ category }}</h3>
            <div class="space-y-2">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between py-2 border-b border-border/50">
                <span class="text-text">{{ acc.code }} - {{ acc.name }}</span>
                <span class="font-mono text-text">{{ formatCurrency(acc.balance) }}</span>
              </div>
            </div>
            <div class="flex justify-between py-3 font-semibold text-text mt-2">
              <span>Total {{ category }}</span>
              <span class="font-mono">{{ formatCurrency(sumCategory(accounts)) }}</span>
            </div>
          </div>
          
          <div class="flex justify-between py-4 px-4 bg-success/10 rounded-lg font-bold">
            <span class="text-success">Total Assets</span>
            <span class="font-mono text-success text-lg">{{ formatCurrency(totalAssets) }}</span>
          </div>
        </div>
      </div>

      <!-- Liabilities Section -->
      <div class="card">
        <div class="flex items-center gap-3 px-6 py-4 bg-danger/10 border-b border-border">
          <Wallet class="w-6 h-6 text-danger" />
          <h2 class="text-lg font-semibold text-text">Liabilities</h2>
        </div>
        
        <div class="p-6 space-y-6">
          <div v-for="(accounts, category) in groupedData.liability" :key="category">
            <h3 class="text-sm font-semibold text-muted uppercase tracking-wider mb-3">{{ category }}</h3>
            <div class="space-y-2">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between py-2 border-b border-border/50">
                <span class="text-text">{{ acc.code }} - {{ acc.name }}</span>
                <span class="font-mono text-text">{{ formatCurrency(acc.balance) }}</span>
              </div>
            </div>
            <div class="flex justify-between py-3 font-semibold text-text mt-2">
              <span>Total {{ category }}</span>
              <span class="font-mono">{{ formatCurrency(sumCategory(accounts)) }}</span>
            </div>
          </div>
          
          <div class="flex justify-between py-4 px-4 bg-danger/10 rounded-lg font-bold">
            <span class="text-danger">Total Liabilities</span>
            <span class="font-mono text-danger text-lg">{{ formatCurrency(totalLiabilities) }}</span>
          </div>
        </div>
      </div>

      <!-- Equity Section -->
      <div class="card">
        <div class="flex items-center gap-3 px-6 py-4 bg-info/10 border-b border-border">
          <Scale class="w-6 h-6 text-info" />
          <h2 class="text-lg font-semibold text-text">Equity</h2>
        </div>
        
        <div class="p-6 space-y-6">
          <div v-for="(accounts, category) in groupedData.equity" :key="category">
            <h3 class="text-sm font-semibold text-muted uppercase tracking-wider mb-3">{{ category }}</h3>
            <div class="space-y-2">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between py-2 border-b border-border/50">
                <span class="text-text">{{ acc.code }} - {{ acc.name }}</span>
                <span class="font-mono text-text">{{ formatCurrency(acc.balance) }}</span>
              </div>
            </div>
          </div>
          
          <div class="flex justify-between py-4 px-4 bg-info/10 rounded-lg font-bold">
            <span class="text-info">Total Equity</span>
            <span class="font-mono text-info text-lg">{{ formatCurrency(totalEquity) }}</span>
          </div>
        </div>
      </div>

      <!-- Balance Check -->
      <div class="card" :class="isBalanced ? 'border-success' : 'border-danger'">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-6">
            <div class="text-right">
              <p class="text-sm text-muted">Total Assets</p>
              <p class="text-2xl font-bold font-mono text-success">{{ formatCurrency(totalAssets) }}</p>
            </div>
            <span class="text-2xl text-muted">=</span>
            <div class="text-left">
              <p class="text-sm text-muted">Liabilities + Equity</p>
              <p class="text-2xl font-bold font-mono text-info">{{ formatCurrency(totalLiabilities + totalEquity) }}</p>
            </div>
          </div>
          <div 
            class="w-12 h-12 rounded-full flex items-center justify-center"
            :class="isBalanced ? 'bg-success/20' : 'bg-danger/20'"
          >
            <CheckCircle v-if="isBalanced" class="w-6 h-6 text-success" />
            <AlertCircle v-else class="w-6 h-6 text-danger" />
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Loader2, Building2, Wallet, Scale, CheckCircle, AlertCircle } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const rawData = ref([])
const loading = ref(true)

const fetchData = async () => {
  loading.value = true
  try {
    const res = await fetch(import.meta.env.VITE_GET_BALANCE_SHEET_WEBHOOK)
    const data = await res.json()
    rawData.value = data
  } catch (e) {
    console.error("Failed to fetch balance sheet", e)
  } finally {
    loading.value = false
  }
}

const groupedData = computed(() => {
  const groups = { asset: {}, liability: {}, equity: {} }
  rawData.value.forEach(item => {
    if (!groups[item.type]) return
    if (!groups[item.type][item.category_label]) {
      groups[item.type][item.category_label] = []
    }
    groups[item.type][item.category_label].push(item)
  })
  return groups
})

const sumCategory = (accounts) => accounts.reduce((s, a) => s + Number(a.balance), 0)

const totalAssets = computed(() => 
  Object.values(groupedData.value.asset).flat().reduce((s, a) => s + Number(a.balance), 0)
)

const totalLiabilities = computed(() => 
  Object.values(groupedData.value.liability).flat().reduce((s, a) => s + Number(a.balance), 0)
)

const totalEquity = computed(() => 
  Object.values(groupedData.value.equity).flat().reduce((s, a) => s + Number(a.balance), 0)
)

const isBalanced = computed(() => Math.abs(totalAssets.value - (totalLiabilities.value + totalEquity.value)) < 0.01)

const formatCurrency = (val) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val)

onMounted(fetchData)

const refresh = () => {
  fetchData()
  emit('refresh')
}
</script>
