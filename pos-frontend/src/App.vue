<script setup>
import { onMounted, ref, computed, watch } from 'vue'
import { usePosStore } from './stores/posStore'
import { 
  ShoppingCart, 
  Search, 
  X, 
  TrendingUp, 
  UserPlus, 
  PackageSearch,
  Sun,
  Moon,
  Check
} from 'lucide-vue-next'

// Components
import ProductCard from './components/ProductCard.vue'
import CartSidebar from './components/CartSidebar.vue'
import SalesModal from './components/SalesModal.vue'
import UserDialogs from './components/UserDialogs.vue'

const store = usePosStore()
const isMobileCartOpen = ref(false)
const searchQuery = ref('')
const showUserDialog = ref(false)
const showSelectionDialog = ref(false)
const userType = ref('site') // 'site' or 'chat'

watch(() => store.theme, (theme) => {
  if (theme === 'dark') {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
}, { immediate: true })

const openCreateUser = () => {
  showSelectionDialog.value = true
}

const selectType = (type) => {
  userType.value = type
  showSelectionDialog.value = false
  showUserDialog.value = true
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
  <div class="flex flex-col lg:flex-row h-screen bg-bg text-text overflow-hidden font-sans transition-colors duration-500">
    
    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- Header: Glass Panel -->
      <header class="glass-panel h-16 lg:h-20 flex items-center justify-between px-4 lg:px-8 shrink-0 z-20 shadow-xl rounded-none border-t-0 border-x-0">
        <div class="flex items-center gap-4 lg:gap-6">
          <div class="relative group">
            <div class="absolute inset-0 bg-primary/10 blur-xl group-hover:bg-primary/20 transition-all duration-500"></div>
            <img 
              :src="store.logo" 
              alt="Logo" 
              class="relative w-10 h-10 lg:w-12 lg:h-12 object-contain brightness-0 dark:invert transition-transform group-hover:scale-105 duration-500" 
            />
          </div>
          <div class="hidden sm:block">
            <h1 class="text-lg lg:text-xl font-black tracking-tight uppercase leading-none">{{store.appTitle}}</h1>
            <p class="text-[10px] font-black text-muted uppercase tracking-[0.4em] mt-1 italic opacity-40">Industrial Sales Terminal</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <!-- Theme Toggle -->
          <button @click="store.toggleTheme()" class="btn-base bg-surface border border-border hover:border-primary/50 hover:text-primary h-10 w-10 p-0" :title="store.theme === 'dark' ? 'Light Mode' : 'Dark Mode'">
            <Sun v-if="store.theme === 'dark'" class="w-4 h-4" />
            <Moon v-else class="w-4 h-4" />
          </button>

          <!-- Create User -->
          <button @click="openCreateUser" class="btn-base bg-surface border border-border hover:border-primary/50 hover:text-primary h-10 w-10 p-0" title="Access Control">
            <UserPlus class="w-4 h-4" />
          </button>

          <!-- Daily Sales -->
          <button @click="store.fetchDailySales()" class="btn-base bg-surface border border-border hover:border-primary/50 hover:text-primary h-10 w-10 p-0" title="Transaction Log">
            <TrendingUp class="w-4 h-4" />
          </button>

          <!-- Mobile Cart Toggle -->
          <button 
            @click="isMobileCartOpen = true" 
            class="lg:hidden relative h-10 px-4 bg-primary/10 border border-primary/30 text-primary flex items-center gap-3 active:scale-95 transition-transform"
          >
            <ShoppingCart class="w-4 h-4" />
            <span class="font-mono font-black text-sm">{{ store.cartCount }}</span>
          </button>
        </div>
      </header>

      <!-- Sub-Header: Search -->
      <div class="px-4 lg:px-8 py-4 lg:py-6 border-b border-border bg-surface/30">
        <div class="max-w-3xl relative group">
          <Search class="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted group-focus-within:text-primary transition-colors" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="SCAN OR SEARCH PRODUCT ID..."
            class="input-industrial w-full pl-14 h-14 bg-bg/80"
          />
          <div class="absolute right-5 top-1/2 -translate-y-1/2 flex items-center gap-2">
             <button v-if="searchQuery" @click="searchQuery = ''" class="text-muted hover:text-white transition-colors p-2">
               <X class="w-4 h-4" />
             </button>
          </div>
        </div>
      </div>
      
      <!-- Products Grid -->
      <div class="flex-1 overflow-y-auto p-4 lg:p-8 custom-scrollbar bg-bg/20">
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-4 lg:gap-6 max-w-[1600px] mx-auto pb-12">
          <ProductCard 
            v-for="product in filteredProducts" 
            :key="product.id"
            :product="product"
          />

          <!-- Empty State -->
          <div v-if="filteredProducts.length === 0 && searchQuery" class="col-span-full py-32 flex flex-col items-center justify-center text-muted border border-dashed border-border bg-surface/5">
            <div class="w-20 h-20 border border-border flex items-center justify-center mb-8 opacity-20">
              <PackageSearch class="w-10 h-10" />
            </div>
            <p class="text-xs font-black uppercase tracking-[0.4em]">Resource Not Found</p>
            <p class="text-[10px] font-bold uppercase tracking-tight mt-2 opacity-40">No records matching "{{ searchQuery }}"</p>
          </div>
        </div>
      </div>
    </main>

    <!-- Cart Sidebar -->
    <CartSidebar 
      :is-open="isMobileCartOpen"
      @close="isMobileCartOpen = false"
    />

    <!-- Mobile Cart Overlay -->
    <div 
      v-if="isMobileCartOpen" 
      @click="isMobileCartOpen = false" 
      class="fixed inset-0 bg-black/90 backdrop-blur-md z-40 lg:hidden"
    ></div>

    <!-- Success Toast -->
    <Transition name="toast">
      <div 
        v-if="store.showSuccessToast" 
        class="fixed top-12 right-12 z-[100] bg-surface border-2 border-primary p-8 shadow-2xl flex items-center gap-8 shadow-primary/20 animate-scale-in rounded-none"
      >
        <div class="w-16 h-16 bg-primary/10 rounded-none flex items-center justify-center border border-primary/20">
          <Check class="w-10 h-10 text-primary" />
        </div>
        <div>
          <p class="text-xs font-black text-text uppercase tracking-[0.4em] leading-none mb-2">Transaction Finalized</p>
          <p class="text-[9px] font-bold text-muted uppercase tracking-widest leading-none italic opacity-60">Record successfully committed to ledger.</p>
        </div>
      </div>
    </Transition>

    <!-- Modals & Dialogs -->
    <SalesModal />
    
    <UserDialogs 
      :show-selection="showSelectionDialog"
      :show-create="showUserDialog"
      :user-type="userType"
      @close-selection="showSelectionDialog = false"
      @close-create="showUserDialog = false"
      @select-type="selectType"
    />
  </div>
</template>

<style scoped>
.animate-scale-in {
  animation: scaleIn 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}
</style>
