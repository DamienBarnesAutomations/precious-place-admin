<script setup>
import { onMounted, ref, computed, reactive } from 'vue'
import { usePosStore } from './stores/posStore'
import { 
  ShoppingCart, 
  Search, 
  X, 
  Plus, 
  Trash2, 
  TrendingUp, 
  UserPlus, 
  Users, 
  ChevronDown,
  ChevronRight,
  Check,
  Loader2
} from 'lucide-vue-next'

const store = usePosStore()
const isMobileCartOpen = ref(false)
const searchQuery = ref('')
const showUserDialog = ref(false)
const showSelectionDialog = ref(false)
const isSubmitting = ref(false)
const userType = ref('site') // 'site' or 'chat'

const userForm = reactive({
  username: '',
  password: '',
  userId: ''
})

const openCreateUser = () => {
  showSelectionDialog.value = true
}

const selectType = (type) => {
  userType.value = type
  showSelectionDialog.value = false
  showUserDialog.value = true
}

const handleCreateUser = async () => {
  const url = userType.value === 'site' ? store.createAdminUserUrl : store.createChatAdminUserUrl
  
  if (!url) {
    alert('Request URL is not configured.')
    return
  }

  isSubmitting.value = true
  try {
    const payload = userType.value === 'site' 
      ? { username: userForm.username, password: userForm.password }
      : { userId: userForm.userId }

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (response.ok) {
      alert('User created successfully!')
      showUserDialog.value = false
      userForm.username = ''
      userForm.password = ''
      userForm.userId = ''
    } else {
      const errorData = await response.json().catch(() => ({}))
      alert(`Failed to create user: ${errorData.message || response.statusText}`)
    }
  } catch (error) {
    console.error('Error creating user:', error)
    alert('An error occurred while creating the user.')
  } finally {
    isSubmitting.value = false
  }
}

const filteredProducts = computed(() => {
  if (!searchQuery.value.trim()) return store.products
  return store.products.filter(p =>
    p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

onMounted(() => {
  if (store.fetchProducts) store.fetchProducts()
})
</script>

<template>
  <div class="flex flex-col lg:flex-row min-h-screen h-screen bg-zinc-950 text-zinc-100 overflow-hidden font-sans">
    
    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col p-4 lg:p-6 overflow-hidden">
      <!-- Header -->
      <header class="flex justify-between items-center mb-4 lg:mb-6">
        <div class="flex items-center gap-3 lg:gap-4">
          <img 
            :src="store.logo" 
            alt="Logo" 
            class="w-12 h-12 lg:w-16 lg:h-16 object-contain brightness-0 invert" 
          />
          <div>
            <h1 class="text-xl lg:text-2xl font-bold tracking-tight">{{store.appTitle}}</h1>
            <p class="text-xs text-zinc-500 hidden sm:block">Point of Sale System</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <!-- Mobile Cart Button -->
          <button 
            @click="isMobileCartOpen = true" 
            class="lg:hidden relative p-2.5 bg-zinc-900 rounded-xl border border-zinc-800 hover:border-emerald-500/50"
          >
            <ShoppingCart class="w-5 h-5 text-emerald-500" />
            <span v-if="store.cartCount > 0" class="absolute -top-1.5 -right-1.5 bg-emerald-500 text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-lg">
              {{ store.cartCount }}
            </span>
          </button>

          <!-- Create User Button -->
          <button 
            @click="openCreateUser" 
            class="p-2.5 hover:bg-zinc-800 rounded-xl border border-zinc-800 hover:border-emerald-500/30 transition-all"
            title="Create User"
          >
            <UserPlus class="w-5 h-5 text-zinc-500 hover:text-emerald-500" />
          </button>

          <!-- Daily Sales Button -->
          <button 
            @click="store.fetchDailySales()" 
            class="p-2.5 hover:bg-zinc-800 rounded-xl border border-zinc-800 hover:border-emerald-500/30 transition-all"
            title="View Daily Sales"
          >
            <TrendingUp class="w-5 h-5 text-zinc-500 hover:text-emerald-500" />
          </button>
        </div>
      </header>

      <!-- Search Bar -->
      <div class="mb-4 lg:mb-6 relative">
        <Search class="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500 pointer-events-none" />
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search products..."
          class="w-full bg-zinc-900 border border-zinc-800 rounded-xl pl-11 pr-10 py-3 text-sm text-zinc-100 placeholder-zinc-500 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
        />
        <button 
          v-if="searchQuery" 
          @click="searchQuery = ''" 
          class="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-500 hover:text-zinc-300 transition-colors"
        >
          <X class="w-4 h-4" />
        </button>
      </div>
      
      <!-- Products Grid -->
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-5 gap-3 lg:gap-4 overflow-y-auto pr-2 custom-scrollbar pb-4">
        <div 
          v-for="product in filteredProducts" 
          :key="product.id"
          @click="store.addToCart(product)"
          class="product-card bg-zinc-900 border border-zinc-800 p-3 lg:p-4 rounded-2xl cursor-pointer hover:border-emerald-500/50 transition-all duration-300 group"
        >
          <div class="aspect-square bg-zinc-800 rounded-xl mb-3 overflow-hidden relative">
            <img 
              :src="store.imageBaseUrl + product.img_url" 
              class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" 
            />
            <!-- Quick add indicator -->
            <div class="absolute inset-0 bg-emerald-500/0 group-hover:bg-emerald-500/10 transition-colors flex items-center justify-center">
              <Plus class="w-6 h-6 text-emerald-500 opacity-0 group-hover:opacity-100 transform scale-50 group-hover:scale-100 transition-all" />
            </div>
          </div>
          <h3 class="font-bold text-xs sm:text-sm truncate mb-1">{{ product.name }}</h3>
          <p class="text-emerald-400 font-mono text-sm font-semibold">{{store.currency}}{{ product.price }}</p>
        </div>

        <!-- Empty State -->
        <div v-if="filteredProducts.length === 0 && searchQuery" class="col-span-full flex flex-col items-center justify-center h-40 text-zinc-600">
          <Search class="w-12 h-12 mb-3 opacity-50" />
          <p>No products found for "{{ searchQuery }}"</p>
        </div>
      </div>
    </main>

    <!-- Cart Sidebar -->
    <aside 
      :class="[
        'fixed inset-y-0 right-0 z-50 w-full sm:w-[380px] lg:w-96 bg-zinc-900 border-l border-zinc-800 flex flex-col shadow-2xl transition-transform duration-300 lg:relative lg:translate-x-0',
        isMobileCartOpen ? 'translate-x-0' : 'translate-x-full'
      ]"
    >
      <!-- Cart Header -->
      <div class="p-5 lg:p-6 border-b border-zinc-800 flex justify-between items-center">
        <div class="flex items-center gap-3">
          <button @click="isMobileCartOpen = false" class="lg:hidden text-zinc-400 hover:text-zinc-200">
            <ChevronRight class="w-5 h-5 rotate-180" />
          </button>
          <div class="flex items-center gap-2">
            <ShoppingCart class="w-5 h-5 text-emerald-500" />
            <h2 class="text-xl font-bold">Current Order</h2>
          </div>
        </div>
        <button 
          @click="store.clearCart" 
          class="text-xs text-zinc-500 hover:text-red-400 underline uppercase tracking-tighter flex items-center gap-1"
        >
          <Trash2 class="w-3 h-3" />
          Clear
        </button>
      </div>

      <!-- Cart Items -->
      <div class="flex-1 overflow-y-auto p-4 lg:p-5 space-y-3 custom-scrollbar">
        <div v-if="store.cart.length === 0" class="h-full flex flex-col items-center justify-center text-zinc-600">
          <ShoppingCart class="w-16 h-16 mb-4 opacity-30" />
          <p class="font-medium">Cart is empty</p>
          <p class="text-sm opacity-60">Click products to add them</p>
        </div>
        
        <TransitionGroup name="cart-item">
          <div 
            v-for="(item, index) in store.cart" 
            :key="index" 
            class="flex items-center gap-3 bg-zinc-950 p-3 lg:p-4 rounded-xl border border-zinc-800"
          >
            <div class="flex-1 min-w-0">
              <h4 class="text-sm font-bold leading-tight truncate">{{ item.name }}</h4>
              <p class="text-xs text-zinc-500 mt-0.5">{{store.currency}}{{ item.price }} × {{ item.quantity }}</p>
            </div>
            <div class="flex items-center gap-3">
              <span class="font-mono text-emerald-400 font-semibold text-sm">{{store.currency}}{{ (item.price * item.quantity).toFixed(2) }}</span>
              <button 
                @click="store.removeFromCart(index)" 
                class="w-8 h-8 flex items-center justify-center bg-zinc-900 rounded-lg text-zinc-500 hover:text-red-500 border border-zinc-700 hover:border-red-500/50 transition-all"
              >
                <Trash2 class="w-4 h-4" />
              </button>
            </div>
          </div>
        </TransitionGroup>
      </div>

      <!-- Cart Footer -->
      <div class="p-5 lg:p-6 bg-zinc-950 border-t border-zinc-800 space-y-4">
        <div class="flex justify-between items-end">
          <span class="text-zinc-500 font-medium">Total</span>
          <span class="text-3xl font-bold text-white">{{store.currency}}{{ store.cartTotal.toFixed(2) }}</span>
        </div>
        <button 
          @click="store.checkout(); isMobileCartOpen = false"
          :disabled="store.loading || store.cart.length === 0"
          class="w-full py-4 rounded-xl font-bold text-lg transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          :class="store.loading ? 'bg-zinc-700 cursor-wait' : 'bg-emerald-600 hover:bg-emerald-500 text-white hover:shadow-lg hover:shadow-emerald-500/20'"
        >
          <Loader2 v-if="store.loading" class="w-5 h-5 animate-spin" />
          <Check v-else class="w-5 h-5" />
          {{ store.loading ? 'PROCESSING...' : 'CHECKOUT' }}
        </button>
      </div>
    </aside>

    <!-- Mobile Cart Overlay -->
    <div 
      v-if="isMobileCartOpen" 
      @click="isMobileCartOpen = false" 
      class="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 lg:hidden"
    ></div>

    <!-- Success Toast -->
    <Transition name="toast">
      <div 
        v-if="store.showSuccessToast" 
        class="fixed top-6 right-6 z-[100] bg-emerald-500 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3 border border-emerald-400"
      >
        <div class="bg-white/20 rounded-full p-1">
          <Check class="w-5 h-5" />
        </div>
        <p class="font-bold">Sale Recorded!</p>
      </div>
    </Transition>

    <!-- Daily Sales Modal -->
    <div v-if="store.showSalesModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md">
      <div class="bg-zinc-900 border border-zinc-800 w-full max-w-2xl rounded-3xl flex flex-col max-h-[85vh] shadow-2xl">
        <div class="p-5 lg:p-6 border-b border-zinc-800 flex justify-between items-center">
          <div class="flex items-center gap-3">
            <TrendingUp class="w-5 h-5 text-emerald-500" />
            <h2 class="text-xl font-bold">Daily Sales Activity</h2>
          </div>
          <button @click="store.showSalesModal = false" class="p-2 hover:bg-zinc-800 rounded-xl text-zinc-400 hover:text-zinc-200 transition-colors">
            <X class="w-5 h-5" />
          </button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-4 lg:p-6 space-y-3 custom-scrollbar">
          <div v-if="!store.groupedSales || store.groupedSales.length === 0" class="flex flex-col items-center justify-center h-40 text-zinc-600 border-2 border-dashed border-zinc-800 rounded-2xl">
            <TrendingUp class="w-12 h-12 mb-3 opacity-30" />
            <p>No transactions found for today.</p>
          </div>

          <div v-for="group in store.groupedSales" :key="group.id" class="border border-zinc-800 rounded-2xl bg-zinc-950/40 overflow-hidden">
            <div @click="store.toggleTransaction(group.id)" class="p-4 flex justify-between items-center cursor-pointer hover:bg-zinc-800/50 transition-colors">
              <div class="flex items-center gap-3">
                <span class="text-[10px] bg-zinc-900 px-2 py-1 rounded font-mono text-zinc-500">
                  {{ new Date(group.time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}
                </span>
                <span class="font-bold text-sm text-zinc-200">Order #{{ group.id }}</span>
              </div>
              <div class="flex items-center gap-3">
                <span class="font-bold text-emerald-400 font-mono text-lg">{{ store.currency }}{{ group.total.toFixed(2) }}</span>
                <ChevronDown 
                  class="w-5 h-5 text-zinc-600 transition-transform duration-300" 
                  :class="{'rotate-180': store.expandedTransactions?.includes(group.id)}" 
                />
              </div>
            </div>

            <div v-if="store.expandedTransactions?.includes(group.id)" class="bg-black/30 border-t border-zinc-800 p-4 space-y-2">
              <div v-for="item in group.items" :key="item.id" class="flex justify-between text-xs sm:text-sm">
                <div class="flex gap-2 text-zinc-300">
                  <span class="text-emerald-500 font-bold opacity-70">{{ item.quantity }}×</span>
                  <span>{{ item.name }}</span>
                </div>
                <span class="text-zinc-500 font-mono">{{ store.currency }}{{ Number(item.total_price).toFixed(2) }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="p-5 lg:p-6 border-t border-zinc-800 bg-zinc-950/80 rounded-b-3xl flex justify-between items-center">
          <div>
            <p class="text-zinc-500 text-[10px] font-bold uppercase tracking-widest leading-none">Day Total</p>
            <p class="text-3xl font-black text-emerald-500 font-mono mt-1">{{ store.currency }}{{ store.dayTotal.toFixed(2) }}</p>
          </div>
          <button 
            @click="store.showSalesModal = false" 
            class="px-6 py-3 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl font-bold text-sm transition-colors"
          >
            CLOSE
          </button>
        </div>
      </div>
    </div>

    <!-- Selection Dialog -->
    <div v-if="showSelectionDialog" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md">
      <div class="bg-zinc-900 border border-zinc-800 w-full max-w-sm rounded-3xl p-6 shadow-2xl">
        <h3 class="text-xl font-bold mb-6 text-center">Add New User</h3>
        <div class="space-y-3">
          <button 
            @click="selectType('site')" 
            class="w-full py-4 bg-zinc-950 border border-zinc-800 hover:border-emerald-500/50 rounded-2xl font-bold text-zinc-100 transition-all flex items-center justify-between px-6 group"
          >
            <span class="flex items-center gap-3">
              <Users class="w-5 h-5 text-zinc-500 group-hover:text-emerald-500" />
              Add Site Admin
            </span>
            <ChevronRight class="w-5 h-5 text-zinc-600 group-hover:text-emerald-500 transition-colors" />
          </button>
          <button 
            @click="selectType('chat')" 
            class="w-full py-4 bg-zinc-950 border border-zinc-800 hover:border-emerald-500/50 rounded-2xl font-bold text-zinc-100 transition-all flex items-center justify-between px-6 group"
          >
            <span class="flex items-center gap-3">
              <UserPlus class="w-5 h-5 text-zinc-500 group-hover:text-emerald-500" />
              Add Chat Admin
            </span>
            <ChevronRight class="w-5 h-5 text-zinc-600 group-hover:text-emerald-500 transition-colors" />
          </button>
          <button 
            @click="showSelectionDialog = false" 
            class="w-full py-3 text-zinc-500 hover:text-zinc-300 font-bold transition-colors mt-2"
          >
            CANCEL
          </button>
        </div>
      </div>
    </div>

    <!-- Create User Dialog -->
    <div v-if="showUserDialog" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md">
      <div class="bg-zinc-900 border border-zinc-800 w-full max-w-md rounded-3xl p-6 shadow-2xl">
        <h3 class="text-xl font-bold mb-6 flex items-center gap-3">
          <UserPlus class="w-5 h-5 text-emerald-500" />
          Add {{ userType === 'site' ? 'Site Admin' : 'Chat Admin' }}
        </h3>
        <form @submit.prevent="handleCreateUser" class="space-y-4">
          <template v-if="userType === 'site'">
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest ml-1">Username</label>
              <input 
                v-model="userForm.username" 
                type="text" 
                required 
                placeholder="Enter username" 
                class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-3 text-zinc-100 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest ml-1">Password</label>
              <input 
                v-model="userForm.password" 
                type="password" 
                required 
                placeholder="Enter password" 
                class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-3 text-zinc-100 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
              />
            </div>
          </template>
          <template v-else>
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest ml-1">User Id</label>
              <input 
                v-model="userForm.userId" 
                type="text" 
                required 
                placeholder="Enter Chat User ID" 
                class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-4 py-3 text-zinc-100 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
              />
            </div>
          </template>
          
          <div class="flex gap-3 pt-4">
            <button 
              type="button" 
              @click="showUserDialog = false" 
              class="flex-1 py-3 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl font-bold transition-colors"
            >
              CANCEL
            </button>
            <button 
              type="submit" 
              :disabled="isSubmitting"
              class="flex-1 py-3 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 disabled:cursor-wait text-white rounded-xl font-bold transition-colors flex items-center justify-center gap-2"
            >
              <Loader2 v-if="isSubmitting" class="w-4 h-4 animate-spin" />
              {{ isSubmitting ? 'CREATING...' : 'SUBMIT' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
