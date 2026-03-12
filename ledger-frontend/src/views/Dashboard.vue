<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  FileText, 
  PlusCircle, 
  Library, 
  Scale, 
  Building2, 
  TrendingUp, 
  DollarSign, 
  Wallet,
  ArrowUpRight,
  ArrowDownRight,
  Clock,
  CheckCircle,
  AlertCircle,
  Loader2,
  Activity,
  ShieldCheck,
  ChevronRight
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

// State
const isLoading = ref(true)
const stats = ref({
  totalTransactions: 0,
  totalDebit: 0,
  totalCredit: 0,
  accountsCount: 0,
  recentActivity: []
})

const journalWebhook = import.meta.env.VITE_GET_JOURNAL_ENTRIES_WEBHOOK
const accountsWebhook = import.meta.env.VITE_GET_ACCOUNTS_WEBHOOK

// Fetch data
const fetchDashboardData = async () => {
  isLoading.value = true
  try {
    // Fetch journal entries
    if (journalWebhook) {
      const journalRes = await fetch(journalWebhook)
      if (journalRes.ok) {
        const journalData = await journalRes.json()
        if (Array.isArray(journalData)) {
          const entries = journalData.filter(e => e && Object.keys(e).length > 0)
          stats.value.totalTransactions = entries.length
          stats.value.totalDebit = entries.reduce((sum, e) => sum + (Number(e.total_debit) || 0), 0)
          stats.value.totalCredit = entries.reduce((sum, e) => sum + (Number(e.total_credit) || 0), 0)
          stats.value.recentActivity = entries.slice(0, 8)
        }
      }
    }

    // Fetch accounts count
    if (accountsWebhook) {
      const accountsRes = await fetch(accountsWebhook)
      if (accountsRes.ok) {
        const accountsData = await accountsRes.json()
        if (Array.isArray(accountsData)) {
          stats.value.accountsCount = accountsData.filter(a => a && Object.keys(a).length > 0).length
        }
      }
    }
  } catch (error) {
    console.error('Error fetching dashboard data:', error)
  } finally {
    isLoading.value = false
  }
}

onMounted(fetchDashboardData)

// Format currency
const formatCurrency = (value) => {
  const num = Number(value) || 0
  return num.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

const systemStatus = computed(() => {
  const variance = Math.abs(stats.value.totalDebit - stats.value.totalCredit)
  return variance < 0.01 ? 'RECONCILED' : 'OUT_OF_BALANCE'
})

const quickLinks = [
  { to: '/accounting/journal/new', icon: PlusCircle, label: 'Post New Entry', desc: 'Add distribution to ledger' },
  { to: '/accounting/create-account', icon: Library, label: 'Setup Account', desc: 'Expand chart of accounts' },
  { to: '/accounting/trial-balance', icon: Scale, label: 'Run Trial Balance', desc: 'Verify ledger integrity' }
]
</script>

<template>
  <div class="space-y-8 animate-fade-in">
    <!-- System Status Banner -->
    <div 
      class="relative overflow-hidden rounded-lg border p-8 shadow-2xl transition-all duration-500"
      :class="systemStatus === 'RECONCILED' ? 'bg-success/5 border-success/30 shadow-glow-success' : 'bg-danger/5 border-danger/30 shadow-glow-danger'"
    >
      <div class="absolute -right-8 -top-8 opacity-5">
        <ShieldCheck v-if="systemStatus === 'RECONCILED'" class="w-64 h-64 text-success" />
        <AlertCircle v-else class="w-64 h-64 text-danger" />
      </div>

      <div class="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-8">
        <div>
          <div class="flex items-center gap-2 mb-2">
            <span :class="['w-2 h-2 rounded-full animate-pulse', systemStatus === 'RECONCILED' ? 'bg-success' : 'bg-danger']"></span>
            <span class="text-[10px] font-black uppercase tracking-[0.3em] text-muted-dark">Ledger Control Status</span>
          </div>
          <h1 class="text-4xl font-black text-text tracking-tighter uppercase mb-2">
            {{ systemStatus === 'RECONCILED' ? 'Systems Reconciled' : 'Variance Detected' }}
          </h1>
          <p class="text-sm text-muted-dark font-bold uppercase tracking-widest">
            Audit Period: Current Fiscal Year <span class="mx-2">|</span> {{ stats.totalTransactions }} Active Records
          </p>
        </div>
        
        <div class="flex items-center gap-12">
          <div class="text-right">
            <p class="text-[10px] font-black text-muted-dark uppercase tracking-widest mb-1">Total Assets (DR)</p>
            <p class="text-3xl font-black font-mono text-text tracking-tighter">${{ formatCurrency(stats.totalDebit) }}</p>
          </div>
          <div class="h-12 w-[1px] bg-border/50"></div>
          <div class="text-right">
            <p class="text-[10px] font-black text-muted-dark uppercase tracking-widest mb-1">Total Equities (CR)</p>
            <p class="text-3xl font-black font-mono text-text tracking-tighter">${{ formatCurrency(stats.totalCredit) }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Dashboard Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      
      <!-- Recent Activity / Audit Trail -->
      <div class="lg:col-span-8 space-y-4">
        <div class="flex items-center justify-between px-2">
          <div class="flex items-center gap-2">
            <Activity class="w-4 h-4 text-primary" />
            <h3 class="text-xs font-black text-text uppercase tracking-widest">Ledger Audit Trail</h3>
          </div>
          <RouterLink to="/accounting/journal" class="text-[10px] font-black text-primary hover:text-primary-hover uppercase tracking-widest flex items-center gap-1 transition-colors">
            Access Archives <ChevronRight class="w-3 h-3" />
          </RouterLink>
        </div>

        <div class="card p-0 overflow-hidden bg-surface/50">
          <div v-if="isLoading" class="flex flex-col items-center justify-center py-24 gap-4 bg-background/20 border-dashed">
            <Loader2 class="w-8 h-8 text-primary animate-spin" />
            <p class="text-[9px] font-black text-muted uppercase tracking-[0.2em]">Querying Distributions...</p>
          </div>

          <div v-else-if="stats.recentActivity.length === 0" class="text-center py-24 border-dashed border-muted/20">
            <FileText class="w-12 h-12 text-muted-dark mx-auto mb-4 opacity-20" />
            <p class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Zero Recent Records</p>
          </div>

          <div v-else class="divide-y divide-border/30">
            <div 
              v-for="(entry, index) in stats.recentActivity" 
              :key="entry.id || index"
              class="group flex items-center gap-6 px-6 py-3.5 hover:bg-background/40 transition-colors"
            >
              <div class="font-mono text-[11px] font-bold text-muted-dark uppercase w-20">
                {{ new Date(entry.entry_date).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) }}
              </div>
              <div class="w-24">
                <span class="px-2 py-0.5 bg-background border border-border text-[9px] font-black text-muted uppercase tracking-tighter rounded font-mono">
                  #{{ entry.reference || '0000' }}
                </span>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-[13px] font-bold text-text-secondary truncate group-hover:text-text transition-colors">
                  {{ entry.description || 'UNSPECIFIED TRANSACTION' }}
                </p>
              </div>
              <div class="text-right w-32">
                <p class="text-[13px] font-black font-mono text-success tracking-tighter">${{ formatCurrency(entry.total_debit) }}</p>
                <p class="text-[9px] font-black text-muted uppercase tracking-tighter leading-none mt-0.5">POSTED_DR</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Operations -->
      <div class="lg:col-span-4 space-y-6">
        <div class="space-y-4">
          <div class="flex items-center gap-2 px-2">
            <PlusCircle class="w-4 h-4 text-primary" />
            <h3 class="text-xs font-black text-text uppercase tracking-widest">Operations</h3>
          </div>
          
          <div class="grid grid-cols-1 gap-3">
            <RouterLink 
              v-for="link in quickLinks" 
              :key="link.to"
              :to="link.to"
              class="card p-4 hover:border-primary/30 group transition-all duration-300"
            >
              <div class="flex items-center gap-4">
                <div class="w-10 h-10 rounded bg-primary/10 flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                  <component :is="link.icon" class="w-5 h-5 text-primary" />
                </div>
                <div class="flex-1">
                  <p class="text-[11px] font-black text-text uppercase tracking-widest mb-0.5">{{ link.label }}</p>
                  <p class="text-[9px] font-bold text-muted-dark uppercase tracking-tighter">{{ link.desc }}</p>
                </div>
                <ArrowUpRight class="w-4 h-4 text-muted-dark group-hover:text-primary group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
              </div>
            </RouterLink>
          </div>
        </div>

        <div class="space-y-4">
          <div class="flex items-center gap-2 px-2">
            <Building2 class="w-4 h-4 text-primary" />
            <h3 class="text-xs font-black text-text uppercase tracking-widest">Financial Context</h3>
          </div>
          <div class="card p-6 bg-primary/5 border-primary/10">
            <div class="space-y-4">
              <div class="flex justify-between items-center">
                <span class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Active Accounts</span>
                <span class="text-lg font-black font-mono text-text tracking-tighter">{{ stats.accountsCount }}</span>
              </div>
              <div class="h-[1px] bg-primary/10"></div>
              <div class="flex justify-between items-center">
                <span class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Compliance Level</span>
                <span class="text-[10px] font-black text-success uppercase tracking-widest px-2 py-0.5 bg-success/10 rounded border border-success/20">Certified</span>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>

    <!-- Financial Reports Section -->
    <div class="space-y-4 pt-4 border-t border-border">
      <div class="flex items-center gap-2 px-2">
        <TrendingUp class="w-4 h-4 text-primary" />
        <h3 class="text-xs font-black text-text uppercase tracking-widest">Reporting Engine</h3>
      </div>
      
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <RouterLink 
          v-for="report in [
            { to: '/accounting/profit-loss', icon: TrendingUp, label: 'Profit & Loss', color: 'text-success' },
            { to: '/accounting/balance-sheet', icon: Building2, label: 'Balance Sheet', color: 'text-info' },
            { to: '/accounting/income-report', icon: DollarSign, label: 'Income Statements', color: 'text-success' },
            { to: '/accounting/expense-report', icon: Wallet, label: 'Expense Analysis', color: 'text-danger' }
          ]"
          :key="report.to"
          :to="report.to"
          class="card p-5 hover:bg-surface-hover group transition-all"
        >
          <div class="flex flex-col items-center text-center gap-3">
            <div class="w-12 h-12 rounded-full bg-background/50 flex items-center justify-center group-hover:scale-110 transition-transform">
              <component :is="report.icon" :class="['w-6 h-6', report.color]" />
            </div>
            <p class="text-[11px] font-black text-text uppercase tracking-[0.2em]">{{ report.label }}</p>
          </div>
        </RouterLink>
      </div>
    </div>
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
