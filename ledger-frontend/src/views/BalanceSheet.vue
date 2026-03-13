<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Loader2, Landmark } from 'lucide-vue-next'

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
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">Balance Sheet</h1>
        <div class="flex items-center gap-2 mt-1">
          <Landmark class="w-3.5 h-3.5 text-muted" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Statement of Financial Position</p>
        </div>
      </div>
      
      <div class="flex items-center gap-4 text-right">
        <div class="hidden sm:block">
          <p class="text-[10px] font-bold text-muted uppercase">As At</p>
          <p class="text-xs font-mono font-bold">{{ new Date().toLocaleDateString('en-GB') }}</p>
        </div>
        <button @click="refresh" class="btn btn-outline h-9">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="ml-1">Refresh</span>
        </button>
      </div>
    </div>

    <!-- Statement Body -->
    <div class="card p-0 overflow-hidden bg-white shadow-sm border-slate-300">
      <div v-if="loading" class="p-24 flex flex-col items-center justify-center gap-3">
        <Loader2 class="w-8 h-8 text-primary animate-spin" />
        <p class="text-xs font-bold text-muted uppercase tracking-widest">Valuating Assets...</p>
      </div>

      <div v-else class="p-8 max-w-4xl mx-auto space-y-10 text-slate-900">
        <!-- ASSETS -->
        <section>
          <h3 class="text-sm font-bold uppercase border-b-2 border-slate-900 pb-1 mb-4">Assets</h3>
          
          <div v-for="(accounts, category) in groupedData.asset" :key="category" class="mb-6">
            <h4 class="text-xs font-bold text-slate-500 uppercase tracking-wide mb-2 pl-2">{{ category }}</h4>
            <div class="space-y-1 pl-4">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between text-sm">
                <span>{{ acc.name }}</span>
                <span class="font-mono">{{ formatCurrency(acc.balance) }}</span>
              </div>
              <div class="flex justify-between text-sm font-bold border-t border-slate-200 mt-1 pt-1">
                <span class="text-[11px] uppercase italic">Total {{ category }}</span>
                <span class="font-mono">{{ formatCurrency(sumCategory(accounts)) }}</span>
              </div>
            </div>
          </div>

          <div class="flex justify-between items-center bg-slate-50 px-4 py-3 border-y border-slate-200 mt-4">
            <span class="text-sm font-bold uppercase tracking-tight">Total Assets</span>
            <span class="font-mono text-lg font-bold underline decoration-double underline-offset-4">
              ${{ formatCurrency(totalAssets) }}
            </span>
          </div>
        </section>

        <!-- LIABILITIES & EQUITY -->
        <section>
          <h3 class="text-sm font-bold uppercase border-b-2 border-slate-900 pb-1 mb-4">Liabilities & Equity</h3>
          
          <!-- Liabilities -->
          <div v-for="(accounts, category) in groupedData.liability" :key="category" class="mb-6">
            <h4 class="text-xs font-bold text-slate-500 uppercase tracking-wide mb-2 pl-2">{{ category }}</h4>
            <div class="space-y-1 pl-4">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between text-sm">
                <span>{{ acc.name }}</span>
                <span class="font-mono">{{ formatCurrency(acc.balance) }}</span>
              </div>
              <div class="flex justify-between text-sm font-bold border-t border-slate-200 mt-1 pt-1">
                <span class="text-[11px] uppercase italic">Total {{ category }}</span>
                <span class="font-mono">{{ formatCurrency(sumCategory(accounts)) }}</span>
              </div>
            </div>
          </div>

          <div class="flex justify-between items-center px-4 py-2 border-b border-slate-200 mb-8">
            <span class="text-xs font-bold uppercase">Total Liabilities</span>
            <span class="font-mono text-sm font-bold">${{ formatCurrency(totalLiabilities) }}</span>
          </div>

          <!-- Equity -->
          <div v-for="(accounts, category) in groupedData.equity" :key="category" class="mb-6">
            <h4 class="text-xs font-bold text-slate-500 uppercase tracking-wide mb-2 pl-2">{{ category }}</h4>
            <div class="space-y-1 pl-4">
              <div v-for="acc in accounts" :key="acc.code" class="flex justify-between text-sm">
                <span>{{ acc.name }}</span>
                <span class="font-mono">{{ formatCurrency(acc.balance) }}</span>
              </div>
              <div class="flex justify-between text-sm font-bold border-t border-slate-200 mt-1 pt-1">
                <span class="text-[11px] uppercase italic">Total {{ category }}</span>
                <span class="font-mono">{{ formatCurrency(sumCategory(accounts)) }}</span>
              </div>
            </div>
          </div>

          <div class="flex justify-between items-center px-4 py-2 border-b border-slate-200 mb-10">
            <span class="text-xs font-bold uppercase">Total Equity</span>
            <span class="font-mono text-sm font-bold">${{ formatCurrency(totalEquity) }}</span>
          </div>

          <!-- Final Sum -->
          <div class="flex justify-between items-center bg-slate-50 px-4 py-3 border-y border-slate-200">
            <span class="text-sm font-bold uppercase tracking-tight">Total Liabilities & Equity</span>
            <span class="font-mono text-lg font-bold underline decoration-double underline-offset-4">
              ${{ formatCurrency(totalLiabilities + totalEquity) }}
            </span>
          </div>
        </section>

        <!-- Status Check Footer -->
        <div class="pt-10 flex items-center justify-center">
          <div 
            class="px-6 py-2 rounded-full border text-[10px] font-bold uppercase tracking-[0.2em]"
            :class="isBalanced ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-rose-50 text-rose-700 border-rose-200 animate-pulse'"
          >
            {{ isBalanced ? 'Statement Reconciled' : 'Discrepancy Detected' }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
