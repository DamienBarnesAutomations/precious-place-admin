<script setup>
import { ref, computed, onMounted } from 'vue'
import { PlusCircle, Loader2, CheckCircle, AlertCircle, Plus, Trash2 } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const entryDate = ref(new Date().toISOString().slice(0, 10))
const reference = ref('')
const description = ref('')
const accounts = ref([])
const loadingAccounts = ref(false)
const isSubmitting = ref(false)
const isSuccess = ref(false)

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
    description.value = ''
    reference.value = ''
    rows.value = [
      { account_id: '', debit: null, credit: null },
      { account_id: '', debit: null, credit: null }
    ]
    entryDate.value = new Date().toISOString().slice(0, 10)
    
    setTimeout(() => {
      isSuccess.value = false
    }, 3000)
    
    emit('refresh')
  } catch (err) {
    alert('Failed to save journal entry')
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
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">New Journal Entry</h1>
        <p class="text-muted mt-1">Create a new journal transaction</p>
      </div>
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-2 px-3 py-1.5 rounded-full border" :class="isBalanced ? 'bg-success/10 border-success/30' : 'bg-danger/10 border-danger/30'">
          <CheckCircle v-if="isBalanced" class="w-4 h-4 text-success" />
          <AlertCircle v-else class="w-4 h-4 text-danger" />
          <span class="text-sm font-medium" :class="isBalanced ? 'text-success' : 'text-danger'">
            {{ isBalanced ? 'Ready to Post' : 'Out of Balance' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Success Message -->
    <Transition name="fade">
      <div v-if="isSuccess" class="card bg-success/10 border-success/30 flex items-center gap-3">
        <CheckCircle class="w-5 h-5 text-success" />
        <span class="text-sm font-medium text-success">Journal entry posted successfully!</span>
      </div>
    </Transition>

    <!-- Entry Form -->
    <div class="space-y-4">
      <!-- Meta Section -->
      <div class="card">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Date</label>
            <input type="date" v-model="entryDate" class="input" />
          </div>
          <div>
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Reference</label>
            <input type="text" v-model="reference" placeholder="Ref #" class="input" />
          </div>
          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Description</label>
            <input type="text" v-model="description" placeholder="Entry description..." class="input" />
          </div>
        </div>
      </div>

      <!-- Lines Section -->
      <div class="card p-0 overflow-hidden">
        <div class="px-6 py-4 bg-gradient-to-r from-primary/10 to-transparent border-b border-border">
          <h3 class="font-semibold text-text">Account Distributions</h3>
        </div>

        <!-- Table Header -->
        <div class="hidden md:grid md:grid-cols-[1fr_160px_160px_50px] gap-4 px-6 py-3 bg-background border-b border-border text-xs font-semibold text-muted uppercase tracking-wider">
          <div>Account</div>
          <div class="text-right">Debit</div>
          <div class="text-right">Credit</div>
          <div></div>
        </div>

        <!-- Lines -->
        <div class="divide-y divide-border">
          <div 
            v-for="(row, i) in rows" 
            :key="i"
            class="grid grid-cols-1 md:grid-cols-[1fr_160px_160px_50px] gap-4 px-6 py-4 items-center"
          >
            <select v-model="row.account_id" class="select">
              <option disabled value="">Select Account...</option>
              <option v-for="a in accounts" :key="a.id" :value="a.id">{{ a.code }} - {{ a.name }}</option>
            </select>
            
            <div>
              <input 
                type="number" 
                v-model.number="row.debit" 
                @input="onDebitInput(row)" 
                placeholder="0.00" 
                class="input text-right font-mono"
                :class="row.debit ? 'text-success' : ''"
              />
            </div>

            <div>
              <input 
                type="number" 
                v-model.number="row.credit" 
                @input="onCreditInput(row)" 
                placeholder="0.00" 
                class="input text-right font-mono"
                :class="row.credit ? 'text-danger' : ''"
              />
            </div>

            <div class="flex justify-end">
              <button 
                @click="removeRow(i)" 
                class="p-2 rounded-lg text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                :disabled="rows.length <= 2"
                :class="{ 'opacity-0': rows.length <= 2 }"
              >
                <Trash2 class="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        <!-- Add Line Button -->
        <div class="px-6 py-4 border-t border-border">
          <button @click="addRow" class="btn btn-outline">
            <Plus class="w-4 h-4" />
            <span>Add Line</span>
          </button>
        </div>

        <!-- Totals -->
        <div class="px-6 py-4 bg-background border-t border-border">
          <div class="flex items-center justify-end gap-8">
            <div class="text-right">
              <p class="text-xs text-muted mb-1">Total Debit</p>
              <p class="text-xl font-bold font-mono" :class="totalDebit > 0 ? 'text-success' : 'text-muted'">
                ${{ totalDebit.toFixed(2) }}
              </p>
            </div>
            <div class="text-right">
              <p class="text-xs text-muted mb-1">Total Credit</p>
              <p class="text-xl font-bold font-mono" :class="totalCredit > 0 ? 'text-danger' : 'text-muted'">
                ${{ totalCredit.toFixed(2) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Submit Button -->
      <div class="flex justify-end">
        <button 
          @click="submitEntry"
          :disabled="!isBalanced || isSubmitting"
          class="btn btn-success"
        >
          <Loader2 v-if="isSubmitting" class="w-5 h-5 animate-spin" />
          <CheckCircle v-else class="w-5 h-5" />
          <span>{{ isSubmitting ? 'Posting...' : 'Post Transaction' }}</span>
        </button>
      </div>
    </div>
  </div>
</template>
