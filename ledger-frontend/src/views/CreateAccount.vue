<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { Users, RefreshCw, Loader2, CheckCircle, AlertCircle } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const loading = ref(false)
const fetchingMetadata = ref(false)
const isSuccess = ref(false)

// Form State
const code = ref('')
const name = ref('')
const type = ref('asset')
const categoryId = ref(null)
const normalBalance = ref('debit')

// Metadata from DB
const allCategories = ref([])

const fetchMetadata = async () => {
  fetchingMetadata.value = true
  try {
    const res = await fetch(import.meta.env.VITE_GET_CATEGORIES_WEBHOOK)
    const data = await res.json()
    
    allCategories.value = Array.isArray(data) ? data : []
    setInitialCategory()
  } catch (err) {
    console.error('Failed to load categories:', err)
  } finally {
    fetchingMetadata.value = false
  }
}

const filteredCategories = computed(() => {
  return allCategories.value.filter(cat => cat.type === type.value)
})

const setInitialCategory = () => {
  if (filteredCategories.value.length > 0) {
    categoryId.value = filteredCategories.value[0].id
  }
}

watch(type, (newType) => {
  normalBalance.value = ['asset', 'expense'].includes(newType) ? 'debit' : 'credit'
  setInitialCategory()
})

onMounted(fetchMetadata)

const submitAccount = async () => {
  if (!code.value || !name.value || !categoryId.value) return
  
  loading.value = true
  const payload = {
    code: code.value.trim(),
    name: name.value.trim(),
    type: type.value,
    category_id: categoryId.value,
    normal_balance: normalBalance.value
  }

  try {
    const res = await fetch(import.meta.env.VITE_CREATE_ACCOUNT_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (!res.ok) throw new Error('Failed to create account')

    isSuccess.value = true
    code.value = ''
    name.value = ''
    
    setTimeout(() => {
      isSuccess.value = false
    }, 3000)
  } catch (err) {
    alert(err.message)
  } finally {
    loading.value = false
  }
}

const refresh = () => {
  fetchMetadata()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Create Account</h1>
        <p class="text-muted mt-1">Add new accounts to your chart of accounts</p>
      </div>
      <button @click="refresh" class="btn btn-outline">
        <RefreshCw class="w-4 h-4" />
      </button>
    </div>

    <!-- Success Message -->
    <Transition name="fade">
      <div v-if="isSuccess" class="card bg-success/10 border-success/30 flex items-center gap-3">
        <CheckCircle class="w-5 h-5 text-success" />
        <span class="text-sm font-medium text-success">Account created successfully!</span>
      </div>
    </Transition>

    <!-- Form -->
    <div class="card max-w-2xl">
      <div class="flex items-center gap-3 mb-6 pb-4 border-b border-border">
        <div class="w-12 h-12 rounded-xl bg-success/10 flex items-center justify-center">
          <Users class="w-6 h-6 text-success" />
        </div>
        <div>
          <h3 class="text-lg font-semibold text-text">Account Configuration</h3>
          <p class="text-sm text-muted">Set up new account details</p>
        </div>
      </div>

      <div class="space-y-6">
        <!-- Account Code & Name -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Account Code</label>
            <input 
              v-model="code" 
              type="text" 
              placeholder="e.g. 1001" 
              class="input"
            />
          </div>
          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Account Name</label>
            <input 
              v-model="name" 
              type="text" 
              placeholder="e.g. Petty Cash" 
              class="input"
            />
          </div>
        </div>

        <!-- Account Type & Category -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Account Type</label>
            <select v-model="type" class="select">
              <option value="asset">Asset</option>
              <option value="liability">Liability</option>
              <option value="equity">Equity</option>
              <option value="income">Income</option>
              <option value="expense">Expense</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-text-secondary mb-1.5">Account Category</label>
            <select 
              v-model="categoryId" 
              class="select"
              :disabled="fetchingMetadata"
            >
              <option v-if="fetchingMetadata" disabled>Loading...</option>
              <option v-else-if="filteredCategories.length === 0" disabled>No categories</option>
              <option v-for="cat in filteredCategories" :key="cat.id" :value="cat.id">
                {{ cat.label }}
              </option>
            </select>
          </div>
        </div>

        <!-- Normal Balance Toggle -->
        <div>
          <label class="block text-sm font-medium text-text-secondary mb-1.5">Normal Balance</label>
          <div class="flex gap-2">
            <button 
              @click="normalBalance = 'debit'"
              :class="[
                'flex-1 py-3 px-4 rounded-lg font-medium transition-all',
                normalBalance === 'debit' 
                  ? 'bg-success text-white shadow-glow-success' 
                  : 'bg-background text-muted hover:text-text border border-border'
              ]"
            >
              Debit
            </button>
            <button 
              @click="normalBalance = 'credit'"
              :class="[
                'flex-1 py-3 px-4 rounded-lg font-medium transition-all',
                normalBalance === 'credit' 
                  ? 'bg-danger text-white shadow-lg' 
                  : 'bg-background text-muted hover:text-text border border-border'
              ]"
            >
              Credit
            </button>
          </div>
        </div>

        <!-- Submit Button -->
        <div class="pt-4 border-t border-border">
          <button 
            @click="submitAccount"
            :disabled="loading || !code || !name || !categoryId"
            class="btn btn-success w-full"
          >
            <Loader2 v-if="loading" class="w-5 h-5 animate-spin" />
            <CheckCircle v-else class="w-5 h-5" />
            <span>{{ loading ? 'Creating...' : 'Create Account' }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
