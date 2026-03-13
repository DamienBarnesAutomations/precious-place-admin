<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  PlusCircle, Library, Scale, Building2, TrendingUp, DollarSign, Wallet,
  ArrowUpRight, ArrowDownRight, Clock, CheckCircle, AlertCircle, Loader2,
  Activity, ShieldCheck, ChevronRight, FileText, LayoutDashboard
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
    if (journalWebhook) {
      const journalRes = await fetch(journalWebhook)
      if (journalRes.ok) {
        const journalData = await journalRes.json()
        if (Array.isArray(journalData)) {
          const entries = journalData.filter(e => e && Object.keys(e).length > 0)
          stats.value.totalTransactions = entries.length
          stats.value.totalDebit = entries.reduce((sum, e) => sum + (Number(e.total_debit) || 0), 0)
          stats.value.totalCredit = entries.reduce((sum, e) => sum + (Number(e.total_credit) || 0), 0)
          stats.value.recentActivity = entries.slice(0, 10)
        }
      }
    }

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

const formatCurrency = (value) => {
  const num = Number(value) || 0
  return num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const systemStatus = computed(() => {
  const variance = Math.abs(stats.value.totalDebit - stats.value.totalCredit)
  return variance < 0.01 ? 'RECONCILED' : 'OUT_OF_BALANCE'
})

const quickLinks = [
  { to: '/accounting/journal/new', icon: PlusCircle, label: 'Post Entry' },
  { to: '/accounting/create-account', icon: Library, label: 'Setup Account' },
  { to: '/accounting/trial-balance', icon: Scale, label: 'Run Audit' }
]
</script>

<template>
  <div class="space-y-8 pb-12">
    <!-- Top Command Row -->
    <div class="flex flex-col lg:flex-row gap-6 items-stretch">
      <!-- High-Contrast Status Banner -->
      <div 
        class="flex-1 rounded-lg border flex flex-col justify-center p-6 relative overflow-hidden"
        :class="systemStatus === 'RECONCILED' ? 'bg-slate-900 border-slate-800' : 'bg-rose-900 border-rose-800'"
      >
        <div class="relative z-10">
          <div class="flex items-center gap-2 mb-2">
            <div :class="['w-2 h-2 rounded-full', systemStatus === 'RECONCILED' ? 'bg-emerald-400 animate-pulse' : 'bg-rose-400 animate-ping']"></div>
            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">System Status</span>
          </div>
          <h1 class="text-2xl font-bold text-white tracking-tight uppercase">
            {{ systemStatus === 'RECONCILED' ? 'Ledger Reconciled' : 'Variance Detected' }}
          </h1>
          <p class="text-xs text-slate-400 mt-1 uppercase tracking-wide">
            {{ stats.totalTransactions }} Active Transactions <span class="mx-2">|</span> Current Fiscal Scope
          </p>
        </div>
        <Activity class="absolute -right-4 -bottom-4 w-32 h-32 text-white/5 rotate-12" />
      </div>

      <!-- Quick Action Bar -->
      <div class="lg:w-80 flex flex-col gap-3">
        <RouterLink 
          v-for="link in quickLinks" 
          :key="link.to"
          :to="link.to"
          class="flex-1 flex items-center justify-between px-4 py-3 bg-white border border-border rounded-lg hover:border-primary hover:shadow-sm transition-all group"
        >
          <div class="flex items-center gap-3">
            <component :is="link.icon" class="w-4 h-4 text-slate-400 group-hover:text-primary" />
            <span class="text-xs font-bold text-slate-700 uppercase tracking-tight">{{ link.label }}</span>
          </div>
          <ChevronRight class="w-3.5 h-3.5 text-slate-300 group-hover:text-primary group-hover:translate-x-0.5 transition-transform" />
        </RouterLink>
      </div>
    </div>

    <!-- Financial KPI Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div v-for="kpi in [
        { label: 'Total Assets (DR)', value: stats.totalDebit, icon: Building2, color: 'text-text' },
        { label: 'Total Equity (CR)', value: stats.totalCredit, icon: Wallet, color: 'text-text' },
        { label: 'Accounts', value: stats.accountsCount, icon: Library, color: 'text-primary', isRaw: true },
        { label: 'Compliance', value: '100%', icon: ShieldCheck, color: 'text-emerald-600', isRaw: true }
      ]" :key="kpi.label" class="card p-5">
        <div class="flex items-center justify-between mb-3">
          <span class="text-[10px] font-bold text-muted uppercase tracking-widest">{{ kpi.label }}</span>
          <component :is="kpi.icon" class="w-4 h-4 text-slate-300" />
        </div>
        <p class="text-xl font-bold tracking-tight font-mono tabular-nums" :class="kpi.color">
          {{ kpi.isRaw ? kpi.value : '$' + formatCurrency(kpi.value) }}
        </p>
      </div>
    </div>

    <!-- Audit Trail Section -->
    <div class="space-y-4">
      <div class="flex items-center justify-between px-1">
        <div class="flex items-center gap-2">
          <Clock class="w-4 h-4 text-slate-400" />
          <h3 class="text-xs font-bold text-text uppercase tracking-wider">Transaction Audit Trail</h3>
        </div>
        <RouterLink to="/accounting/journal" class="text-[10px] font-bold text-primary hover:underline uppercase tracking-widest">
          View Full Journal
        </RouterLink>
      </div>

      <div class="card overflow-hidden p-0 border-slate-300">
        <div v-if="isLoading" class="p-24 flex flex-col items-center justify-center gap-3">
          <Loader2 class="w-8 h-8 text-primary animate-spin" />
          <p class="text-xs font-bold text-muted uppercase tracking-widest">Querying Transactions...</p>
        </div>

        <table v-else class="w-full">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200">
              <th class="pl-6 w-32 py-2.5">Date</th>
              <th class="w-24 py-2.5">Ref</th>
              <th class="py-2.5">Description</th>
              <th class="text-right pr-6 w-40 py-2.5">Amount</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 bg-white">
            <tr v-for="entry in stats.recentActivity" :key="entry.id" class="hover:bg-slate-50 transition-colors">
              <td class="pl-6 py-2.5 font-mono text-xs text-muted-dark uppercase">
                {{ new Date(entry.entry_date).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) }}
              </td>
              <td class="py-2.5">
                <span class="text-[10px] font-mono text-slate-500">#{{ entry.reference || '---' }}</span>
              </td>
              <td class="py-2.5 text-xs font-medium text-text-secondary">
                {{ entry.description || 'Unspecified Transaction' }}
              </td>
              <td class="pr-6 py-2.5 text-right font-mono text-xs font-bold text-slate-700 tabular-nums">
                {{ formatCurrency(entry.total_debit) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Reports Access Strip -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <RouterLink 
        v-for="report in [
          { to: '/accounting/profit-loss', label: 'P&L Statement' },
          { to: '/accounting/balance-sheet', label: 'Balance Sheet' },
          { to: '/accounting/income-report', label: 'Income Audit' },
          { to: '/accounting/expense-report', label: 'Expense Audit' }
        ]"
        :key="report.to"
        :to="report.to"
        class="bg-slate-100 border border-slate-200 px-4 py-3 rounded text-center hover:bg-white hover:border-primary transition-all group"
      >
        <span class="text-[10px] font-bold text-slate-500 uppercase tracking-widest group-hover:text-primary transition-colors">
          {{ report.label }}
        </span>
      </RouterLink>
    </div>
  </div>
</template>
