<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Loader2, Building2, Wallet, Scale, CheckCircle, AlertCircle, ShieldCheck, Landmark } from 'lucide-vue-next'

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
  <div class="space-y-6 animate-fade-in pb-12">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-6">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <Landmark class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Financial Position</span>
        </div>
        <h1 class="text-3xl font-black text-text tracking-tighter uppercase">Balance Sheet</h1>
      </div>
      
      <div class="flex items-center gap-3">
        <div class="hidden sm:block text-right">
          <p class="text-[9px] font-black text-muted uppercase tracking-widest">Reporting Date</p>
          <p class="text-[11px] font-bold text-text uppercase">AS AT {{ new Date().toLocaleDateString('en-GB').toUpperCase() }}</p>
        </div>
        <div class="h-8 w-[1px] bg-border mx-2 hidden sm:block"></div>
        <button @click="refresh" class="btn btn-outline h-9 px-4">
          <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
          <span class="text-[11px] font-black uppercase tracking-widest ml-1">Refresh</span>
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card flex flex-col items-center justify-center py-24 gap-4 bg-background/20 border-dashed">
      <Loader2 class="w-10 h-10 text-primary animate-spin" />
      <p class="text-[10px] font-black text-muted uppercase tracking-[0.3em]">Valuating Assets...</p>
    </div>

    <template v-else>
      <div class="grid grid-cols-1 gap-8">
        <!-- Balance Sheet Report Card -->
        <div class="card p-0 overflow-hidden border-border bg-surface shadow-2xl">
          <div class="px-8 py-4 bg-background/50 border-b border-border flex items-center justify-between">
            <h2 class="text-[11px] font-black text-text uppercase tracking-[0.2em]">Summary Statement of Financial Position</h2>
            <div 
              class="flex items-center gap-2 px-2 py-0.5 rounded bg-background border border-border"
              :class="isBalanced ? 'text-success border-success/30' : 'text-danger border-danger/30'"
            >
              <div :class="['w-1.5 h-1.5 rounded-full', isBalanced ? 'bg-success' : 'bg-danger animate-pulse']"></div>
              <span class="text-[9px] font-black uppercase tracking-widest">{{ isBalanced ? 'RECONCILED' : 'DISCREPANCY' }}</span>
            </div>
          </div>

          <div class="p-8 space-y-12">
            <!-- ASSETS -->
            <section class="space-y-6">
              <div class="flex items-center gap-2 border-b border-border pb-2">
                <Building2 class="w-3.5 h-3.5 text-success" />
                <h3 class="text-[11px] font-black text-muted-dark uppercase tracking-widest">Assets (Economic Resources)</h3>
              </div>
              
              <div class="space-y-6 px-4">
                <div v-for="(accounts, category) in groupedData.asset" :key="category" class="space-y-2">
                  <h4 class="text-[10px] font-black text-muted uppercase tracking-widest">{{ category }}</h4>
                  <div class="space-y-1.5 pl-4">
                    <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group">
                      <span class="text-[13px] font-bold text-text-secondary group-hover:text-text transition-colors tracking-tight uppercase">{{ acc.code }} · {{ acc.name }}</span>
                      <div class="flex-1 border-b border-dotted border-border mx-4 mb-1"></div>
                      <span class="font-mono text-[13px] font-black text-text">{{ formatCurrency(acc.balance) }}</span>
                    </div>
                  </div>
                  <div class="flex justify-between items-center pl-4 py-1 border-t border-border/30 mt-2">
                    <span class="text-[10px] font-bold text-muted-dark uppercase italic">Subtotal {{ category }}</span>
                    <span class="font-mono text-[12px] font-bold text-text-secondary">{{ formatCurrency(sumCategory(accounts)) }}</span>
                  </div>
                </div>
              </div>

              <div class="flex justify-between items-center px-6 py-4 bg-success/5 rounded border border-success/10 mt-4 relative">
                <span class="text-[12px] font-black text-success uppercase tracking-[0.2em]">Total Aggregate Assets</span>
                <div class="relative">
                  <span class="font-mono text-xl font-black text-success tracking-tighter">${{ formatCurrency(totalAssets) }}</span>
                  <div class="absolute -bottom-1 left-0 right-0 h-[3px] border-b border-t border-success/30"></div>
                </div>
              </div>
            </section>

            <!-- LIABILITIES & EQUITY -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-12 pt-4 border-t border-border">
              <!-- LIABILITIES -->
              <section class="space-y-6">
                <div class="flex items-center gap-2 border-b border-border pb-2">
                  <Wallet class="w-3.5 h-3.5 text-danger" />
                  <h3 class="text-[11px] font-black text-muted-dark uppercase tracking-widest">Liabilities (Obligations)</h3>
                </div>
                
                <div class="space-y-6 px-4">
                  <div v-for="(accounts, category) in groupedData.liability" :key="category" class="space-y-2">
                    <h4 class="text-[9px] font-black text-muted uppercase tracking-widest">{{ category }}</h4>
                    <div class="space-y-1.5 pl-4">
                      <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group">
                        <span class="text-[12px] font-bold text-text-secondary tracking-tight uppercase">{{ acc.name }}</span>
                        <div class="flex-1 border-b border-dotted border-border mx-4 mb-1"></div>
                        <span class="font-mono text-[12px] font-bold text-text">{{ formatCurrency(acc.balance) }}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex justify-between items-center px-4 py-2 bg-danger/5 rounded border border-danger/10">
                  <span class="text-[10px] font-black text-danger uppercase tracking-widest">Total Liabilities</span>
                  <span class="font-mono text-base font-black text-danger tracking-tighter">${{ formatCurrency(totalLiabilities) }}</span>
                </div>
              </section>

              <!-- EQUITY -->
              <section class="space-y-6">
                <div class="flex items-center gap-2 border-b border-border pb-2">
                  <Scale class="w-3.5 h-3.5 text-info" />
                  <h3 class="text-[11px] font-black text-muted-dark uppercase tracking-widest">Equity (Ownership)</h3>
                </div>
                
                <div class="space-y-6 px-4">
                  <div v-for="(accounts, category) in groupedData.equity" :key="category" class="space-y-2">
                    <h4 class="text-[9px] font-black text-muted uppercase tracking-widest">{{ category }}</h4>
                    <div class="space-y-1.5 pl-4">
                      <div v-for="acc in accounts" :key="acc.code" class="flex justify-between items-end group">
                        <span class="text-[12px] font-bold text-text-secondary tracking-tight uppercase">{{ acc.name }}</span>
                        <div class="flex-1 border-b border-dotted border-border mx-4 mb-1"></div>
                        <span class="font-mono text-[12px] font-bold text-text">{{ formatCurrency(acc.balance) }}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex justify-between items-center px-4 py-2 bg-info/5 rounded border border-info/10">
                  <span class="text-[10px] font-black text-info uppercase tracking-widest">Total Shareholder Equity</span>
                  <span class="font-mono text-base font-black text-info tracking-tighter">${{ formatCurrency(totalEquity) }}</span>
                </div>
              </section>
            </div>

            <!-- FINAL BALANCING -->
            <div class="mt-8 p-8 bg-background/50 rounded-lg border-2 border-dashed border-border flex flex-col md:flex-row items-center justify-between gap-8">
              <div class="flex items-center gap-6">
                <div class="w-16 h-16 rounded-full bg-surface border border-border flex items-center justify-center shadow-lg">
                  <ShieldCheck v-if="isBalanced" class="w-8 h-8 text-success" />
                  <AlertCircle v-else class="w-8 h-8 text-danger" />
                </div>
                <div>
                  <p class="text-[10px] font-black text-muted uppercase tracking-[0.3em] mb-1">Accounting Equation</p>
                  <h4 class="text-xl font-black text-text uppercase tracking-tighter">
                    {{ isBalanced ? 'Ledger Reconciled' : 'Discrepancy Found' }}
                  </h4>
                  <p class="text-[10px] text-muted-dark font-bold uppercase tracking-widest mt-1">Assets = Liabilities + Equity</p>
                </div>
              </div>

              <div class="flex items-center gap-12">
                <div class="text-center">
                  <p class="text-[9px] font-black text-muted uppercase mb-1">Total Resources</p>
                  <p class="text-2xl font-black font-mono text-success tracking-tighter">${{ formatCurrency(totalAssets) }}</p>
                </div>
                <span class="text-2xl font-black text-border">=</span>
                <div class="text-center">
                  <p class="text-[9px] font-black text-muted uppercase mb-1">Total Claims</p>
                  <p class="text-2xl font-black font-mono text-info tracking-tighter">${{ formatCurrency(totalLiabilities + totalEquity) }}</p>
                </div>
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
