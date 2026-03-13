<script setup>
import { ref, computed, onMounted } from 'vue'
import { PlusCircle, Loader2, CheckCircle, AlertCircle, Plus, Trash2, ArrowRight, ShieldCheck, FileSpreadsheet, Save } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const entryDate = ref(new Date().toISOString().slice(0, 10))
const reference = ref('')
const description = ref('')
const accounts = ref([])
const loadingAccounts = ref(false)
const isSubmitting = ref(false)
const isSuccess = ref(false)
const isReviewing = ref(false)

// Start with enough rows for a standard transaction
const rows = ref([
  { account_id: '', debit: null, credit: null },
  { account_id: '', debit: null, credit: null },
  { account_id: '', debit: null, credit: null },
  { account_id: '', debit: null, credit: null }
])

const addRow = () => rows.value.push({ account_id: '', debit: null, credit: null })
const removeRow = (i) => rows.value.length > 2 && rows.value.splice(i, 1)

// Auto-clear opposite field
const onDebitInput = (r) => { if (r.debit) r.credit = null }
const onCreditInput = (r) => { if (r.credit) r.debit = null }

const totalDebit = computed(() => {
  const sum = rows.value.reduce((s, r) => s + (Number(r.debit) || 0), 0)
  return Math.round((sum + Number.EPSILON) * 100) / 100
})

const totalCredit = computed(() => {
  const sum = rows.value.reduce((s, r) => s + (Number(r.credit) || 0), 0)
  return Math.round((sum + Number.EPSILON) * 100) / 100
})

const balance = computed(() => {
  return Math.round((totalDebit.value - totalCredit.value + Number.EPSILON) * 100) / 100
})

const isBalanced = computed(() => {
  return Math.abs(balance.value) === 0 && totalDebit.value > 0
})

const getAccountName = (id) => {
  const acc = accounts.value.find(a => a.id === id)
  return acc ? `${acc.code} · ${acc.name}` : 'Unknown Account'
}

const submitEntry = async () => {
  if (!isBalanced.value) return
  
  const cleanedLines = rows.value
    .filter(r => r.account_id && (Number(r.debit) || Number(r.credit)))
    .map(r => ({
      account_id: r.account_id,
      debit: Number(r.debit) || 0,
      credit: Number(r.credit) || 0
    }))

  if (cleanedLines.length < 2) {
    alert('Journal entry must have at least two lines')
    return
  }

  isSubmitting.value = true
  const payload = {
    date: entryDate.value,
    reference: reference.value,
    description: description.value?.trim() || null,
    lines: cleanedLines
  }

  try {
    const res = await fetch(import.meta.env.VITE_POST_JOURNAL_ENTRIES_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)

    isSuccess.value = true
    isReviewing.value = false
    description.value = ''
    reference.value = ''
    rows.value = [
      { account_id: '', debit: null, credit: null },
      { account_id: '', debit: null, credit: null },
      { account_id: '', debit: null, credit: null },
      { account_id: '', debit: null, credit: null }
    ]
    entryDate.value = new Date().toISOString().slice(0, 10)
    
    setTimeout(() => {
      isSuccess.value = false
    }, 3000)
    
    emit('refresh')
  } catch (err) {
    alert('RECONCILIATION_FAILED: Check entry details and try again.')
  } finally {
    isSubmitting.value = false
  }
}

onMounted(async () => {
  loadingAccounts.value = true
  try {
    const res = await fetch(import.meta.env.VITE_GET_ACCOUNTS_WEBHOOK)
    const data = await res.json()
    accounts.value = Array.isArray(data) ? data : []
  } catch (e) { console.error(e) }
  finally { loadingAccounts.value = false }
})
</script>

<template>
  <div class="space-y-6 pb-32">
    <!-- Header -->
    <div class="flex items-center justify-between border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">New Journal Entry</h1>
        <div class="flex items-center gap-2 mt-1">
          <FileSpreadsheet class="w-3.5 h-3.5 text-muted" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Manual Ledger Adjustment</p>
        </div>
      </div>
      
      <div v-if="!isReviewing" class="flex items-center gap-3">
        <button 
          v-if="!isBalanced"
          class="btn btn-outline text-muted cursor-default hover:bg-white hover:text-muted"
        >
           <span class="tabular-nums">Variance: ${{ balance.toFixed(2) }}</span>
        </button>
      </div>
    </div>

    <!-- Success Overlay -->
    <Transition name="fade">
      <div v-if="isSuccess" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-sm">
        <div class="bg-surface border border-success/30 shadow-2xl rounded-lg p-8 text-center max-w-sm w-full mx-4">
          <div class="w-12 h-12 bg-success-light rounded-full flex items-center justify-center mx-auto mb-4 text-success-text">
            <ShieldCheck class="w-6 h-6" />
          </div>
          <h3 class="text-lg font-bold text-text uppercase tracking-wide mb-2">Posted Successfully</h3>
          <p class="text-xs text-muted font-medium mb-6">Reference ID generated. Ledger updated.</p>
          <button @click="isSuccess = false" class="btn btn-primary w-full justify-center">
            Continue Working
          </button>
        </div>
      </div>
    </Transition>

    <div v-if="!isReviewing" class="space-y-6">
      <!-- Meta Card -->
      <div class="card p-5 bg-slate-50">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-5">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-dark uppercase tracking-wider">Date</label>
            <input type="date" v-model="entryDate" class="input input-mono" />
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-dark uppercase tracking-wider">Reference</label>
            <input type="text" v-model="reference" placeholder="REF-001" class="input input-mono uppercase" />
          </div>
          <div class="md:col-span-2 space-y-1">
             <label class="text-[10px] font-bold text-muted-dark uppercase tracking-wider">Memo / Description</label>
            <input type="text" v-model="description" placeholder="Adjustment for..." class="input" />
          </div>
        </div>
      </div>

      <!-- Ledger Table -->
      <div class="card p-0 overflow-hidden shadow-sm">
        <div class="bg-slate-100 border-b border-border px-4 py-2 flex items-center gap-2">
           <span class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Transaction Lines</span>
        </div>
        
        <table class="w-full">
          <thead>
            <tr>
              <th class="w-8 pl-4 pr-2">#</th>
              <th class="w-[40%]">Account</th>
              <th class="text-right w-[20%]">Debit</th>
              <th class="text-right w-[20%]">Credit</th>
              <th class="w-10"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border/50 bg-white">
            <tr v-for="(row, i) in rows" :key="i" class="group hover:bg-slate-50/80 transition-colors">
              <td class="pl-4 pr-2 text-xs font-mono text-muted/50">{{ i + 1 }}</td>
              <td class="py-1">
                 <select v-model="row.account_id" class="input border-transparent bg-transparent shadow-none focus:ring-0 px-2 font-medium">
                  <option value="" disabled>Select Account...</option>
                  <option v-for="a in accounts" :key="a.id" :value="a.id">
                    {{ a.code }} - {{ a.name }}
                  </option>
                </select>
              </td>
              <td class="py-1 border-l border-border/30">
                <input 
                  type="number" 
                  v-model.number="row.debit" 
                  @input="onDebitInput(row)"
                  placeholder="0.00"
                  class="input border-transparent bg-transparent shadow-none focus:ring-0 text-right font-mono tabular-nums placeholder:text-slate-200"
                />
              </td>
              <td class="py-1 border-l border-border/30">
                <input 
                  type="number" 
                  v-model.number="row.credit" 
                  @input="onCreditInput(row)"
                  placeholder="0.00"
                  class="input border-transparent bg-transparent shadow-none focus:ring-0 text-right font-mono tabular-nums placeholder:text-slate-200"
                />
              </td>
              <td class="text-center">
                <button 
                  @click="removeRow(i)"
                  class="text-muted/30 hover:text-danger transition-colors p-1"
                  tabindex="-1"
                >
                  <Trash2 class="w-3.5 h-3.5" />
                </button>
              </td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="5" class="px-4 py-2 bg-slate-50 border-t border-border">
                <button @click="addRow" class="text-xs font-bold text-primary hover:text-primary-hover uppercase tracking-wider flex items-center gap-1">
                  <PlusCircle class="w-3.5 h-3.5" /> Add Line
                </button>
              </td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>

    <!-- Review Mode -->
    <div v-else class="card max-w-2xl mx-auto p-0 overflow-hidden">
      <div class="px-6 py-4 bg-slate-50 border-b border-border">
        <h3 class="text-sm font-bold text-text uppercase tracking-wide">Confirm Posting</h3>
      </div>
      <div class="p-6 space-y-6">
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="block text-[10px] font-bold text-muted uppercase">Date</span>
            <span class="font-mono">{{ entryDate }}</span>
          </div>
          <div>
            <span class="block text-[10px] font-bold text-muted uppercase">Reference</span>
            <span class="font-mono">{{ reference || 'N/A' }}</span>
          </div>
          <div class="col-span-2">
            <span class="block text-[10px] font-bold text-muted uppercase">Memo</span>
            <span>{{ description || 'No description' }}</span>
          </div>
        </div>

        <div class="border rounded border-border overflow-hidden">
          <table class="w-full text-sm">
            <thead class="bg-slate-50">
              <tr>
                <th class="py-2 px-3 text-left text-xs font-bold text-muted uppercase">Account</th>
                <th class="py-2 px-3 text-right text-xs font-bold text-muted uppercase">Debit</th>
                <th class="py-2 px-3 text-right text-xs font-bold text-muted uppercase">Credit</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border/50">
              <tr v-for="(row, i) in rows.filter(r => r.account_id)" :key="i">
                <td class="py-2 px-3">{{ getAccountName(row.account_id) }}</td>
                <td class="py-2 px-3 text-right font-mono text-muted-dark">{{ row.debit ? row.debit.toFixed(2) : '-' }}</td>
                <td class="py-2 px-3 text-right font-mono text-muted-dark">{{ row.credit ? row.credit.toFixed(2) : '-' }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-slate-50 font-bold">
              <tr>
                <td class="py-2 px-3 text-right uppercase text-[10px]">Totals</td>
                <td class="py-2 px-3 text-right font-mono">{{ totalDebit.toFixed(2) }}</td>
                <td class="py-2 px-3 text-right font-mono">{{ totalCredit.toFixed(2) }}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
      <div class="px-6 py-4 bg-slate-50 border-t border-border flex justify-end gap-3">
        <button @click="isReviewing = false" class="btn btn-outline">Edit</button>
        <button @click="submitEntry" :disabled="isSubmitting" class="btn btn-primary px-6">
          <Loader2 v-if="isSubmitting" class="w-4 h-4 animate-spin" />
          {{ isSubmitting ? 'Posting...' : 'Post Entry' }}
        </button>
      </div>
    </div>

    <!-- Sticky Balance Footer -->
    <div 
      class="fixed bottom-0 left-0 right-0 bg-white border-t border-border p-4 shadow-lg z-30 transition-transform duration-200 lg:pl-[240px]"
      :class="{ 'translate-y-full': isReviewing }"
    >
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <div class="flex items-center gap-8">
           <div class="flex items-center gap-3">
              <div :class="['w-3 h-3 rounded-full', isBalanced ? 'bg-success' : 'bg-danger animate-pulse']"></div>
              <div>
                <p class="text-[10px] font-bold uppercase tracking-widest text-muted">Status</p>
                <p :class="['text-xs font-bold uppercase', isBalanced ? 'text-success-text' : 'text-danger-text']">
                  {{ isBalanced ? 'Balanced' : 'Out of Balance' }}
                </p>
              </div>
           </div>
           <div class="h-8 w-px bg-border hidden sm:block"></div>
           <div class="hidden sm:flex gap-8">
             <div>
               <span class="block text-[10px] font-bold text-muted uppercase">Total Debit</span>
               <span class="font-mono text-sm font-bold">${{ totalDebit.toFixed(2) }}</span>
             </div>
             <div>
               <span class="block text-[10px] font-bold text-muted uppercase">Total Credit</span>
               <span class="font-mono text-sm font-bold">${{ totalCredit.toFixed(2) }}</span>
             </div>
           </div>
        </div>
        
        <button 
          @click="isReviewing = true"
          :disabled="!isBalanced"
          class="btn btn-primary px-6 h-10 shadow-lg shadow-primary/20"
        >
          <span>Review & Post</span>
          <ArrowRight class="w-4 h-4" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
