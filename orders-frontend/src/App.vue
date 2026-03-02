<script setup>
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import { 
  Calendar, 
  Clock, 
  User, 
  Phone, 
  FileText, 
  CheckCircle2, 
  Package, 
  Truck, 
  AlertCircle,
  ChevronRight,
  ChevronLeft,
  Filter
} from 'lucide-vue-next'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '/webhook/'
const orders = ref([])
const loading = ref(true)
const selectedOrder = ref(null)
const filterStatus = ref('All')

const statusColors = {
  'Pending': 'text-amber-400 bg-amber-400/10 border-amber-400/20',
  'Confirmed': 'text-blue-400 bg-blue-400/10 border-blue-400/20',
  'In Progress': 'text-purple-400 bg-purple-400/10 border-purple-400/20',
  'Ready': 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20',
  'Delivered': 'text-zinc-400 bg-zinc-400/10 border-zinc-400/20'
}

const statusIcons = {
  'Pending': Clock,
  'Confirmed': CheckCircle2,
  'In Progress': Package,
  'Ready': Truck,
  'Delivered': CheckCircle2
}

const fetchOrders = async () => {
  loading.value = true
  try {
    const response = await axios.get(`${apiBaseUrl}custom-orders/list`)
    orders.value = response.data
  } catch (error) {
    console.error('Failed to fetch orders:', error)
  } finally {
    loading.value = false
  }
}

const updateStatus = async (orderId, newStatus) => {
  try {
    await axios.post(`${apiBaseUrl}custom-orders/update-status`, {
      orderId,
      status: newStatus
    })
    // Update local state
    const order = orders.value.find(o => o.id === orderId)
    if (order) order.status = newStatus
    if (selectedOrder.value?.id === orderId) selectedOrder.value.status = newStatus
  } catch (error) {
    console.error('Failed to update status:', error)
  }
}

const filteredOrders = computed(() => {
  let result = [...orders.value]
  if (filterStatus.value !== 'All') {
    result = result.filter(o => o.status === filterStatus.value)
  }
  return result.sort((a, b) => new Date(a.order_date) - new Date(b.order_date))
})

const formatDate = (dateStr) => {
  return new Date(dateStr).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric'
  })
}

onMounted(fetchOrders)
</script>

<template>
  <div class="min-h-screen flex flex-col font-sans selection:bg-emerald-500/30">
    <!-- Header -->
    <header class="h-16 border-b border-zinc-800 bg-zinc-950/50 backdrop-blur-md sticky top-0 z-30 px-6 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 bg-emerald-600 rounded-xl flex items-center justify-center shadow-lg shadow-emerald-900/20">
          <Calendar class="text-white w-6 h-6" />
        </div>
        <h1 class="text-xl font-bold tracking-tight">Cake Scheduling</h1>
      </div>

      <div class="flex items-center gap-4">
        <select 
          v-model="filterStatus"
          class="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:border-emerald-500 transition-colors"
        >
          <option>All</option>
          <option>Pending</option>
          <option>Confirmed</option>
          <option>In Progress</option>
          <option>Ready</option>
          <option>Delivered</option>
        </select>
        <button 
          @click="fetchOrders"
          class="p-2 hover:bg-zinc-800 rounded-lg transition-colors text-zinc-400 hover:text-white"
        >
          <Clock :class="{'animate-spin': loading}" class="w-5 h-5" />
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 p-6 max-w-7xl mx-auto w-full">
      <div v-if="loading && orders.length === 0" class="flex flex-col items-center justify-center h-64 text-zinc-500">
        <div class="animate-pulse flex flex-col items-center">
          <div class="w-12 h-12 bg-zinc-800 rounded-full mb-4"></div>
          <p>Loading schedule...</p>
        </div>
      </div>

      <div v-else-if="filteredOrders.length === 0" class="flex flex-col items-center justify-center h-64 text-zinc-500 border-2 border-dashed border-zinc-800 rounded-3xl">
        <AlertCircle class="w-12 h-12 mb-4 opacity-20" />
        <p>No orders found for this view.</p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div 
          v-for="order in filteredOrders" 
          :key="order.id"
          @click="selectedOrder = order"
          class="bg-zinc-900/50 border border-zinc-800 rounded-3xl p-6 hover:border-emerald-500/50 transition-all cursor-pointer group active:scale-[0.98]"
        >
          <div class="flex justify-between items-start mb-4">
            <div class="flex flex-col">
              <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 mb-1">Due Date</span>
              <span class="text-lg font-bold text-emerald-400 font-mono">{{ formatDate(order.order_date) }}</span>
            </div>
            <span :class="statusColors[order.status]" class="px-3 py-1 rounded-full text-[10px] font-bold border">
              {{ order.status.toUpperCase() }}
            </span>
          </div>

          <div class="space-y-3">
            <div class="flex items-center gap-3 text-zinc-200">
              <User class="w-4 h-4 text-zinc-500" />
              <span class="font-bold truncate">{{ order.client_name }}</span>
            </div>
            <div class="flex items-center gap-3 text-zinc-400 text-sm">
              <FileText class="w-4 h-4 text-zinc-600" />
              <p class="line-clamp-2 italic">{{ order.notes || 'No notes' }}</p>
            </div>
          </div>

          <div v-if="order.attachment_url" class="mt-4 aspect-video rounded-2xl overflow-hidden bg-zinc-800 border border-zinc-700">
            <img :src="order.attachment_url" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
          </div>

          <div class="mt-4 pt-4 border-t border-zinc-800/50 flex justify-between items-center text-[10px] text-zinc-500 font-bold">
            <span>#{{ order.id }}</span>
            <div class="flex items-center gap-1 text-emerald-500 opacity-0 group-hover:opacity-100 transition-opacity">
              VIEW DETAILS <ChevronRight class="w-3 h-3" />
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Detail Modal -->
    <Transition name="fade">
      <div v-if="selectedOrder" @click="selectedOrder = null" class="fixed inset-0 bg-black/80 backdrop-blur-md z-[100] flex items-center justify-center p-4">
        <div @click.stop class="bg-zinc-900 border border-zinc-800 w-full max-w-2xl rounded-[2.5rem] flex flex-col max-h-[90vh] shadow-2xl overflow-hidden">
          <!-- Modal Header -->
          <div class="p-8 border-b border-zinc-800 flex justify-between items-start">
            <div>
              <div class="flex items-center gap-3 mb-2">
                <span :class="statusColors[selectedOrder.status]" class="px-4 py-1.5 rounded-full text-xs font-black border uppercase tracking-widest">
                  {{ selectedOrder.status }}
                </span>
                <span class="text-zinc-500 text-sm font-mono">Order #{{ selectedOrder.id }}</span>
              </div>
              <h2 class="text-3xl font-black">{{ selectedOrder.client_name }}</h2>
            </div>
            <button @click="selectedOrder = null" class="p-3 bg-zinc-800 hover:bg-zinc-700 rounded-2xl transition-colors">
              <AlertCircle class="w-6 h-6 rotate-45" />
            </button>
          </div>

          <!-- Modal Body -->
          <div class="flex-1 overflow-y-auto p-8 custom-scrollbar space-y-8">
            <div class="grid grid-cols-2 gap-6">
              <div class="bg-zinc-950 p-6 rounded-3xl border border-zinc-800">
                <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 block mb-2">Collection Date</span>
                <div class="flex items-center gap-3">
                  <Calendar class="text-emerald-500 w-5 h-5" />
                  <span class="text-xl font-bold font-mono">{{ formatDate(selectedOrder.order_date) }}</span>
                </div>
              </div>
              <div class="bg-zinc-950 p-6 rounded-3xl border border-zinc-800">
                <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 block mb-2">Contact</span>
                <div class="flex items-center gap-3">
                  <Phone class="text-emerald-500 w-5 h-5" />
                  <span class="text-xl font-bold font-mono">{{ selectedOrder.client_phone || 'N/A' }}</span>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Order Details</span>
              <div class="bg-zinc-950 p-8 rounded-3xl border border-zinc-800 leading-relaxed text-zinc-300 italic text-lg">
                {{ selectedOrder.notes }}
              </div>
            </div>

            <div v-if="selectedOrder.attachment_url" class="space-y-4">
              <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Attachment</span>
              <img :src="selectedOrder.attachment_url" class="w-full rounded-3xl border border-zinc-800" />
            </div>

            <div class="space-y-4">
              <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 block">Raw Message</span>
              <div class="bg-zinc-950 p-4 rounded-xl border border-zinc-800 text-xs text-zinc-600 font-mono break-words">
                {{ selectedOrder.raw_message }}
              </div>
            </div>
          </div>

          <!-- Modal Footer (Status Update) -->
          <div class="p-8 border-t border-zinc-800 bg-zinc-950/50">
            <span class="text-[10px] font-black uppercase tracking-widest text-zinc-500 block mb-4">Update Status</span>
            <div class="flex flex-wrap gap-2">
              <button 
                v-for="status in ['Pending', 'Confirmed', 'In Progress', 'Ready', 'Delivered']"
                :key="status"
                @click="updateStatus(selectedOrder.id, status)"
                :class="[
                  selectedOrder.status === status ? 'bg-emerald-600 text-white border-emerald-500' : 'bg-zinc-900 text-zinc-400 border-zinc-800 hover:border-zinc-700'
                ]"
                class="px-4 py-2 rounded-xl text-xs font-bold border transition-all active:scale-95"
              >
                {{ status }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
