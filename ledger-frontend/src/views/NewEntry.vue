<script setup>
import { ref, computed, onMounted } from 'vue'
import { PlusCircle, Loader2, CheckCircle, AlertCircle, Plus, Trash2, ArrowRight, ShieldCheck, FileSpreadsheet } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const entryDate = ref(new Date().toISOString().slice(0, 10))
const reference = ref('')
const description = ref('')
const accounts = ref([])
const loadingAccounts = ref(false)
const isSubmitting = ref(false)
const isSuccess = ref(false)
const isReviewing = ref(false)

const rows = ref([
  { account_id: '', debit: null, credit: null },
  { account_id: '', debit: null, credit: null }
])

const addRow = () => rows.value.push({ account_id: '', debit: null, credit: null })
const removeRow = (i) => rows.value.length > 2 && rows.value.splice(i, 1)

const onDebitInput = (r) => { if (r.debit > 0) r.credit = null }
const onCreditInput = (r) => { if (r.credit > 0) r.debit = null }

const totalDebit = computed(() => {
  const sum = rows.value.reduce((s, r) => s + (Number(r.debit) || 0), 0);
  return Math.round((sum + Number.EPSILON) * 100) / 100;
});

const totalCredit = computed(() => {
  const sum = rows.value.reduce((s, r) => s + (Number(r.credit) || 0), 0);
  return Math.round((sum + Number.EPSILON) * 100) / 100;
});

const balance = computed(() => {
  return Math.round((totalDebit.value - totalCredit.value + Number.EPSILON) * 100) / 100;
});

const isBalanced = computed(() => {
  return Math.abs(balance.value) === 0 && totalDebit.value > 0;
});

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
      { account_id: '', debit: null, credit: null }
    ]
    entryDate.value = new Date().toISOString().slice(0, 10)
    
    setTimeout(() => {
      isSuccess.value = false
    }, 4000)
    
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
  <div class="space-y-6 pb-24 relative min-h-full">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4 border-b border-border pb-6">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <FileSpreadsheet class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Transaction Registry</span>
        </div>
        <h1 class="text-3xl font-black text-text tracking-tighter uppercase">New Journal Entry</h1>
      </div>
      
      <div v-if="!isReviewing" class="flex items-center gap-3">
        <div 
          class="flex items-center gap-2 px-3 py-1.5 rounded border transition-colors duration-300" 
          :class="isBalanced ? 'bg-success/5 border-success/30 text-success' : 'bg-danger/5 border-danger/30 text-danger'"
        >
          <div :class="['p-0.5 rounded-full', isBalanced ? 'bg-success/20' : 'bg-danger/20']">
            <CheckCircle v-if="isBalanced" class="w-3.5 h-3.5" />
            <AlertCircle v-else class="w-3.5 h-3.5" />
          </div>
          <span class="text-[11px] font-black uppercase tracking-widest">
            {{ isBalanced ? 'System Reconciled' : 'Unbalanced' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Success Feedback Overlay -->
    <Transition name="fade">
      <div v-if="isSuccess" class="absolute inset-0 z-50 flex items-center justify-center p-6 backdrop-blur-md">
        <div class="card max-w-sm w-full text-center p-12 border-success/30 shadow-glow-success animate-scale-in">
          <div class="w-16 h-16 bg-success/10 rounded-full flex items-center justify-center mx-auto mb-6">
            <ShieldCheck class="w-8 h-8 text-success" />
          </div>
          <h3 class="text-xl font-black text-text uppercase tracking-tighter mb-2">Entry Reconciled</h3>
          <p class="text-xs text-muted font-bold uppercase tracking-widest leading-relaxed mb-8">
            Transaction has been successfully committed to the General Ledger.
          </p>
          <button @click="isSuccess = false" class="btn btn-success w-full">
            <span class="text-[11px] font-black uppercase tracking-widest">Create Another</span>
          </button>
        </div>
      </div>
    </Transition>

    <div v-if="!isReviewing" class="space-y-6 animate-fade-in">
      <!-- Meta Section -->
      <div class="grid grid-cols-1 md:grid-cols-12 gap-6">
        <div class="md:col-span-8 space-y-4">
          <div class="card bg-background/30 p-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-1.5">
                <label class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Transaction Date</label>
                <input type="date" v-model="entryDate" class="input font-mono" />
              </div>
              <div class="space-y-1.5">
                <label class="text-[10px] font-black text-muted-dark uppercase tracking-widest">External Reference</label>
                <input type="text" v-model="reference" placeholder="REF_0000" class="input font-mono uppercase" />
              </div>
              <div class="md:col-span-2 space-y-1.5">
                <label class="text-[10px] font-black text-muted-dark uppercase tracking-widest">Entry Memo / Description</label>
                <input type="text" v-model="description" placeholder="Describe the transaction intent..." class="input" />
              </div>
            </div>
          </div>
        </div>

        <div class="md:col-span-4 flex flex-col">
          <div class="card bg-primary/5 border-primary/20 flex-1 flex flex-col justify-center p-6 relative overflow-hidden">
            <div class="absolute -right-4 -bottom-4 opacity-5 rotate-12">
              <PlusCircle class="w-32 h-32 text-primary" />
            </div>
            <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-4">Verification Stats</p>
            <div class="space-y-4">
              <div class="flex justify-between items-end border-b border-primary/10 pb-2">
                <span class="text-[10px] font-bold text-muted uppercase">Line Count</span>
                <span class="text-lg font-black font-mono text-text tracking-tighter">{{ rows.length }}</span>
              </div>
              <div class="flex justify-between items-end border-b border-primary/10 pb-2">
                <span class="text-[10px] font-bold text-muted uppercase">Variance</span>
                <span :class="['text-lg font-black font-mono tracking-tighter', balance === 0 ? 'text-success' : 'text-danger']">
                  {{ balance.toFixed(2) }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Distributions Table -->
      <div class="card p-0 overflow-hidden border-border bg-surface shadow-lg">
        <div class="px-6 py-3 bg-background/50 border-b border-border flex items-center justify-between">
          <h3 class="text-[11px] font-black text-text uppercase tracking-widest">Account Distributions</h3>
          <span class="text-[9px] font-bold text-muted uppercase tracking-tighter">Double-Entry Ledger</span>
        </div>

        <!-- Ledger Header -->
        <div class="grid grid-cols-[1fr_150px_150px_48px] gap-0 text-[10px] font-black text-muted uppercase tracking-widest bg-background/80 border-b border-border text-center">
          <div class="px-6 py-2 text-left border-r border-border">Account Specification</div>
          <div class="px-4 py-2 border-r border-border">Debit</div>
          <div class="px-4 py-2 border-r border-border">Credit</div>
          <div class="px-2 py-2"></div>
        </div>

        <!-- Ledger Rows -->
        <div class="divide-y divide-border">
          <div 
            v-for="(row, i) in rows" 
            :key="i"
            class="grid grid-cols-[1fr_150px_150px_48px] gap-0 items-stretch group hover:bg-surface-hover transition-colors"
          >
            <div class="px-6 py-3 border-r border-border flex items-center">
              <select v-model="row.account_id" class="select bg-transparent border-transparent focus:ring-0 px-0 h-auto">
                <option disabled value="">Select target account...</option>
                <option v-for="a in accounts" :key="a.id" :value="a.id">{{ a.code }} — {{ a.name }}</option>
              </select>
            </div>
            
            <div class="border-r border-border">
              <input 
                type="number" 
                v-model.number="row.debit" 
                @input="onDebitInput(row)" 
                placeholder="0.00" 
                class="w-full h-full bg-transparent text-right font-mono px-4 focus:bg-background/40 focus:outline-none focus:ring-1 focus:ring-primary/20 text-success font-bold"
              />
            </div>

            <div class="border-r border-border">
              <input 
                type="number" 
                v-model.number="row.credit" 
                @input="onCreditInput(row)" 
                placeholder="0.00" 
                class="w-full h-full bg-transparent text-right font-mono px-4 focus:bg-background/40 focus:outline-none focus:ring-1 focus:ring-primary/20 text-danger font-bold"
              />
            </div>

            <div class="flex items-center justify-center bg-background/10">
              <button 
                @click="removeRow(i)" 
                class="p-2 text-muted-dark hover:text-danger transition-colors disabled:opacity-0"
                :disabled="rows.length <= 2"
              >
                <Trash2 class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        <!-- Add Line Footer -->
        <div class="px-6 py-3 bg-background/20 border-t border-border">
          <button @click="addRow" class="btn btn-outline border-dashed border-muted-dark/50 hover:border-primary/50 group">
            <Plus class="w-3.5 h-3.5 group-hover:text-primary transition-colors" />
            <span class="text-[11px] font-black uppercase tracking-widest">Insert Ledger Line</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Review State -->
    <div v-else class="animate-scale-in">
      <div class="card p-0 overflow-hidden border-primary/30 shadow-glow-primary">
        <div class="px-6 py-4 bg-primary/10 border-b border-primary/20 flex items-center gap-3">
          <ShieldCheck class="w-5 h-5 text-primary" />
          <div>
            <h3 class="text-sm font-black text-text uppercase tracking-widest">Final Review Required</h3>
            <p class="text-[10px] font-bold text-primary uppercase tracking-tighter">Please verify all accounting distributions before commitment</p>
          </div>
        </div>

        <div class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6 text-sm">
            <div>
              <p class="text-[10px] font-black text-muted-dark uppercase tracking-widest mb-1">Date</p>
              <p class="font-mono font-bold text-text">{{ entryDate }}</p>
            </div>
            <div>
              <p class="text-[10px] font-black text-muted-dark uppercase tracking-widest mb-1">Reference</p>
              <p class="font-mono font-bold text-text">{{ reference || 'N/A' }}</p>
            </div>
            <div>
              <p class="text-[10px] font-black text-muted-dark uppercase tracking-widest mb-1">Memo</p>
              <p class="font-bold text-text truncate">{{ description || 'No Description provided' }}</p>
            </div>
          </div>

          <div class="table-container border-primary/10">
            <table class="table">
              <thead>
                <tr class="bg-primary/5">
                  <th class="border-primary/10">Account Account</th>
                  <th class="text-right border-primary/10">Debit</th>
                  <th class="text-right border-primary/10">Credit</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in rows.filter(r => r.account_id)" :key="i">
                  <td>{{ getAccountName(row.account_id) }}</td>
                  <td class="text-right font-mono font-bold" :class="row.debit ? 'text-success' : 'text-muted-dark'">
                    {{ row.debit ? row.debit.toFixed(2) : '—' }}
                  </td>
                  <td class="text-right font-mono font-bold" :class="row.credit ? 'text-danger' : 'text-muted-dark'">
                    {{ row.credit ? row.credit.toFixed(2) : '—' }}
                  </td>
                </tr>
              </tbody>
              <tfoot class="bg-primary/5 font-black">
                <tr>
                  <td class="text-right text-muted-dark uppercase tracking-widest">Verification Totals</td>
                  <td class="text-right font-mono text-success text-base">${{ totalDebit.toFixed(2) }}</td>
                  <td class="text-right font-mono text-danger text-base">${{ totalCredit.toFixed(2) }}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        <div class="px-6 py-4 bg-background/50 border-t border-border flex justify-end gap-3">
          <button @click="isReviewing = false" class="btn btn-ghost">
            <span class="text-[11px] font-black uppercase tracking-widest">Back to Editor</span>
          </button>
          <button @click="submitEntry" :disabled="isSubmitting" class="btn btn-primary px-8">
            <Loader2 v-if="isSubmitting" class="w-4 h-4 animate-spin" />
            <span class="text-[11px] font-black uppercase tracking-widest">{{ isSubmitting ? 'Committing...' : 'Commit Transaction' }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Sticky Live Balance Bar -->
    <div 
      class="fixed bottom-0 left-0 lg:left-64 right-0 bg-surface/90 backdrop-blur-xl border-t border-border shadow-[0_-10px_20px_-10px_rgba(0,0,0,0.5)] z-40 px-6 py-3 transition-transform duration-300 translate-y-0"
      v-if="!isSuccess"
    >
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <div class="flex items-center gap-8">
          <div class="hidden sm:block">
            <p class="text-[9px] font-black text-muted uppercase tracking-widest">Reconciliation Status</p>
            <div class="flex items-center gap-2 mt-0.5">
              <div :class="['w-2 h-2 rounded-full', isBalanced ? 'bg-success animate-pulse' : 'bg-danger']"></div>
              <span :class="['text-xs font-black uppercase tracking-tighter', isBalanced ? 'text-success' : 'text-danger']">
                {{ isBalanced ? 'Balanced' : 'Out of Balance' }}
              </span>
            </div>
          </div>
          <div class="h-8 w-[1px] bg-border hidden sm:block"></div>
          <div class="flex gap-6">
            <div class="text-right">
              <p class="text-[9px] font-black text-muted uppercase tracking-widest mb-0.5">Debit Sum</p>
              <p class="text-sm font-black font-mono text-text">${{ totalDebit.toFixed(2) }}</p>
            </div>
            <div class="text-right">
              <p class="text-[9px] font-black text-muted uppercase tracking-widest mb-0.5">Credit Sum</p>
              <p class="text-sm font-black font-mono text-text">${{ totalCredit.toFixed(2) }}</p>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <button 
            v-if="!isReviewing"
            @click="isReviewing = true"
            :disabled="!isBalanced"
            class="btn btn-primary"
          >
            <span class="text-[11px] font-black uppercase tracking-widest">Review Record</span>
            <ArrowRight class="w-3.5 h-3.5 ml-1" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Page Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.animate-fade-in {
  animation: fadeIn 0.4s ease-out;
}

.animate-scale-in {
  animation: scaleIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}
</style>
