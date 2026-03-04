<script setup>
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import { 
  Calendar, Clock, User, Phone, FileText, CheckCircle2, 
  Package, Truck, AlertCircle, ChevronRight, X,
  RefreshCw, Filter, Pencil, Check, Loader2
} from 'lucide-vue-next'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '/webhook/'
const orders = ref([])
const loading = ref(true)
const selectedOrder = ref(null)
const filterStatus = ref('All')
const showFilter = ref(false)

const editMode = ref(false)
const saving = ref(false)
const editForm = ref({})

const statusColors = {
  'Pending':    { pill: 'text-amber-400 bg-amber-400/10 border-amber-400/20',       dot: 'bg-amber-400' },
  'Confirmed':  { pill: 'text-sky-400 bg-sky-400/10 border-sky-400/20',             dot: 'bg-sky-400' },
  'In Progress':{ pill: 'text-violet-400 bg-violet-400/10 border-violet-400/20',    dot: 'bg-violet-400' },
  'Ready':      { pill: 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20', dot: 'bg-emerald-400' },
  'Delivered':  { pill: 'text-zinc-400 bg-zinc-400/10 border-zinc-400/20',          dot: 'bg-zinc-500' }
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
    await axios.post(`${apiBaseUrl}custom-orders/update-status`, { orderId, status: newStatus })
    const order = orders.value.find(o => o.id === orderId)
    if (order) order.status = newStatus
    if (selectedOrder.value?.id === orderId) selectedOrder.value.status = newStatus
  } catch (error) {
    console.error('Failed to update status:', error)
  }
}

const openEdit = () => {
  editForm.value = {
    client_name: selectedOrder.value.client_name,
    client_phone: selectedOrder.value.client_phone || '',
    order_date: selectedOrder.value.order_date?.slice(0, 10) ?? '',
    notes: selectedOrder.value.notes || '',
  }
  editMode.value = true
}

const cancelEdit = () => {
  editMode.value = false
  editForm.value = {}
}

const saveEdit = async () => {
  saving.value = true
  try {
    await axios.post(`${apiBaseUrl}custom-orders/update`, {
      orderId: selectedOrder.value.id,
      ...editForm.value
    })
    const order = orders.value.find(o => o.id === selectedOrder.value.id)
    const updated = { ...selectedOrder.value, ...editForm.value }
    if (order) Object.assign(order, editForm.value)
    selectedOrder.value = updated
    editMode.value = false
  } catch (error) {
    console.error('Failed to save order:', error)
  } finally {
    saving.value = false
  }
}

const closeModal = () => {
  selectedOrder.value = null
  editMode.value = false
  editForm.value = {}
}

const filteredOrders = computed(() => {
  let result = [...orders.value]
  if (filterStatus.value !== 'All') result = result.filter(o => o.status === filterStatus.value)
  return result.sort((a, b) => new Date(a.order_date) - new Date(b.order_date))
})

const formatDate = (dateStr) => new Date(dateStr).toLocaleDateString('en-GB', {
  day: 'numeric', month: 'short', year: 'numeric'
})

const formatDateShort = (dateStr) => new Date(dateStr).toLocaleDateString('en-GB', {
  day: 'numeric', month: 'short'
})

const statuses = ['All', 'Pending', 'Confirmed', 'In Progress', 'Ready', 'Delivered']

onMounted(fetchOrders)
</script>

<template>
  <div class="min-h-screen bg-zinc-950 text-zinc-100 font-sans selection:bg-emerald-500/30 antialiased">

    <!-- Header -->
    <header class="sticky top-0 z-30 border-b border-white/5 bg-zinc-950/80 backdrop-blur-xl">
      <div class="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between gap-3">
        <div class="flex items-center gap-2.5">
          <div class="w-8 h-8 bg-gradient-to-br from-emerald-500 to-emerald-700 rounded-lg flex items-center justify-center shadow-lg shadow-emerald-900/40 shrink-0">
            <Calendar class="text-white w-4 h-4" />
          </div>
          <span class="font-semibold tracking-tight text-sm">Cake Scheduling</span>
        </div>
        <div class="flex items-center gap-2">
          <button
            @click="showFilter = !showFilter"
            :class="filterStatus !== 'All' ? 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30' : 'text-zinc-400 bg-zinc-900 border-zinc-800'"
            class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-xs font-medium transition-all"
          >
            <Filter class="w-3.5 h-3.5" />
            <span class="hidden sm:inline">{{ filterStatus }}</span>
          </button>
          <button
            @click="fetchOrders"
            :class="{'animate-spin': loading}"
            class="w-8 h-8 flex items-center justify-center rounded-lg text-zinc-500 hover:text-zinc-300 hover:bg-zinc-800 transition-all"
          >
            <RefreshCw class="w-4 h-4" />
          </button>
        </div>
      </div>
      <Transition name="slide-down">
        <div v-if="showFilter" class="border-t border-white/5 bg-zinc-900/80 backdrop-blur-xl px-4 py-3">
          <div class="max-w-6xl mx-auto flex gap-2 flex-wrap">
            <button
              v-for="s in statuses" :key="s"
              @click="filterStatus = s; showFilter = false"
              :class="filterStatus === s ? 'bg-emerald-600 text-white border-emerald-500' : 'text-zinc-400 bg-zinc-900 border-zinc-800 hover:border-zinc-600'"
              class="px-3 py-1.5 rounded-lg border text-xs font-medium transition-all"
            >{{ s }}</button>
          </div>
        </div>
      </Transition>
    </header>

    <!-- Main -->
    <main class="max-w-6xl mx-auto px-4 py-6 pb-24">
      <div v-if="loading && orders.length === 0" class="flex flex-col items-center justify-center h-60 gap-3 text-zinc-600">
        <div class="w-8 h-8 border-2 border-zinc-700 border-t-emerald-500 rounded-full animate-spin"></div>
        <p class="text-sm">Loading orders...</p>
      </div>

      <div v-else-if="filteredOrders.length === 0" class="flex flex-col items-center justify-center h-60 text-zinc-600 rounded-2xl border border-dashed border-zinc-800">
        <AlertCircle class="w-8 h-8 mb-3 opacity-30" />
        <p class="text-sm">No orders for this view</p>
      </div>

      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        <div
          v-for="order in filteredOrders" :key="order.id"
          @click="selectedOrder = order"
          class="group relative bg-zinc-900 border border-white/5 rounded-2xl overflow-hidden cursor-pointer transition-all duration-200 hover:border-emerald-500/30 hover:shadow-lg hover:shadow-emerald-950/50 active:scale-[0.98]"
        >
          <div :class="statusColors[order.status]?.dot" class="absolute top-0 left-0 right-0 h-0.5 opacity-70"></div>
          <div class="p-4">
            <div class="flex items-start justify-between gap-2 mb-3">
              <div>
                <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-0.5">Due</p>
                <p class="text-base font-bold text-emerald-400 tabular-nums leading-none">{{ formatDateShort(order.order_date) }}</p>
              </div>
              <span :class="statusColors[order.status]?.pill" class="px-2.5 py-1 rounded-full text-[10px] font-bold border leading-none shrink-0">
                {{ order.status.toUpperCase() }}
              </span>
            </div>
            <div class="flex items-center gap-2 mb-2">
              <div class="w-6 h-6 rounded-full bg-zinc-800 flex items-center justify-center shrink-0">
                <User class="w-3 h-3 text-zinc-500" />
              </div>
              <span class="font-semibold text-sm truncate">{{ order.client_name }}</span>
            </div>
            <p class="text-zinc-500 text-xs leading-relaxed line-clamp-2 italic pl-8">{{ order.notes || 'No notes' }}</p>
            <div v-if="order.attachment_url" class="mt-3 aspect-video rounded-xl overflow-hidden bg-zinc-800">
              <img :src="order.attachment_url" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
            </div>
            <div class="mt-3 flex items-center justify-between">
              <span class="text-[10px] text-zinc-700 font-mono">#{{ order.id }}</span>
              <span class="text-[10px] text-emerald-500 font-semibold flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                View <ChevronRight class="w-3 h-3" />
              </span>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Detail / Edit Modal -->
    <Transition name="modal">
      <div v-if="selectedOrder" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
        <div @click="closeModal" class="absolute inset-0 bg-black/70 backdrop-blur-sm"></div>
        <div @click.stop class="relative bg-zinc-900 border border-white/8 w-full sm:max-w-2xl sm:rounded-3xl rounded-t-3xl flex flex-col max-h-[92dvh] sm:max-h-[88vh] shadow-2xl overflow-hidden">

          <!-- Drag handle (mobile) -->
          <div class="sm:hidden flex justify-center pt-3 pb-1">
            <div class="w-9 h-1 rounded-full bg-zinc-700"></div>
          </div>

          <!-- Modal Header -->
          <div class="px-6 pt-4 pb-4 border-b border-white/5 flex justify-between items-start gap-4">
            <div class="min-w-0">
              <div class="flex items-center gap-2 mb-1.5 flex-wrap">
                <span :class="statusColors[selectedOrder.status]?.pill" class="px-3 py-1 rounded-full text-[10px] font-bold border uppercase tracking-wider">
                  {{ selectedOrder.status }}
                </span>
                <span class="text-zinc-600 text-xs font-mono">Order #{{ selectedOrder.id }}</span>
              </div>
              <h2 class="text-2xl font-bold truncate">
                {{ editMode ? (editForm.client_name || selectedOrder.client_name) : selectedOrder.client_name }}
              </h2>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <button
                v-if="!editMode"
                @click="openEdit"
                class="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white text-xs font-semibold border border-white/5 transition-all"
              >
                <Pencil class="w-3.5 h-3.5" />
                Edit
              </button>
              <button
                v-else
                @click="cancelEdit"
                class="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-zinc-400 hover:text-zinc-200 text-xs font-semibold border border-white/5 transition-all"
              >
                Cancel
              </button>
              <button @click="closeModal" class="w-9 h-9 rounded-xl bg-zinc-800 hover:bg-zinc-700 flex items-center justify-center transition-colors">
                <X class="w-4 h-4 text-zinc-400" />
              </button>
            </div>
          </div>

          <!-- Modal Body -->
          <div class="flex-1 overflow-y-auto p-6 space-y-5 overscroll-contain">

            <!-- VIEW MODE -->
            <template v-if="!editMode">
              <div class="grid grid-cols-2 gap-3">
                <div class="bg-zinc-950/60 rounded-2xl p-4 border border-white/5">
                  <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-2">Collection Date</p>
                  <div class="flex items-center gap-2">
                    <Calendar class="text-emerald-500 w-4 h-4 shrink-0" />
                    <span class="text-sm font-bold font-mono">{{ formatDate(selectedOrder.order_date) }}</span>
                  </div>
                </div>
                <div class="bg-zinc-950/60 rounded-2xl p-4 border border-white/5">
                  <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-2">Contact</p>
                  <div class="flex items-center gap-2">
                    <Phone class="text-emerald-500 w-4 h-4 shrink-0" />
                    <span class="text-sm font-bold font-mono truncate">{{ selectedOrder.client_phone || 'N/A' }}</span>
                  </div>
                </div>
              </div>

              <div>
                <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-2">Order Details</p>
                <div class="bg-zinc-950/60 rounded-2xl p-5 border border-white/5 text-zinc-300 italic text-sm leading-relaxed">
                  {{ selectedOrder.notes || '—' }}
                </div>
              </div>

              <div v-if="selectedOrder.attachment_url">
                <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-2">Attachment</p>
                <img :src="selectedOrder.attachment_url" class="w-full rounded-2xl border border-white/5" />
              </div>

              <div>
                <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-2">Raw Message</p>
                <div class="bg-zinc-950/60 rounded-xl p-4 border border-white/5 text-xs text-zinc-600 font-mono break-words leading-relaxed">
                  {{ selectedOrder.raw_message }}
                </div>
              </div>
            </template>

            <!-- EDIT MODE -->
            <template v-else>
              <div class="space-y-4">
                <div>
                  <label class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold block mb-2">Client Name</label>
                  <input
                    v-model="editForm.client_name"
                    type="text"
                    placeholder="Client name"
                    class="w-full bg-zinc-950/60 border border-white/8 rounded-xl px-4 py-3 text-sm text-zinc-100 placeholder-zinc-600 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
                  />
                </div>
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold block mb-2">Collection Date</label>
                    <input
                      v-model="editForm.order_date"
                      type="date"
                      class="w-full bg-zinc-950/60 border border-white/8 rounded-xl px-4 py-3 text-sm text-zinc-100 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
                    />
                  </div>
                  <div>
                    <label class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold block mb-2">Phone</label>
                    <input
                      v-model="editForm.client_phone"
                      type="tel"
                      placeholder="+44 7700 000000"
                      class="w-full bg-zinc-950/60 border border-white/8 rounded-xl px-4 py-3 text-sm text-zinc-100 placeholder-zinc-600 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all"
                    />
                  </div>
                </div>
                <div>
                  <label class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold block mb-2">Order Details / Notes</label>
                  <textarea
                    v-model="editForm.notes"
                    rows="5"
                    placeholder="Describe the order..."
                    class="w-full bg-zinc-950/60 border border-white/8 rounded-xl px-4 py-3 text-sm text-zinc-100 placeholder-zinc-600 focus:outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 transition-all resize-none leading-relaxed"
                  ></textarea>
                </div>
              </div>
            </template>

          </div>

          <!-- Modal Footer -->
          <div class="px-6 py-4 border-t border-white/5 bg-zinc-950/40">

            <!-- Edit mode: Save button -->
            <div v-if="editMode">
              <button
                @click="saveEdit"
                :disabled="saving"
                class="w-full flex items-center justify-center gap-2 py-3 rounded-2xl bg-emerald-600 hover:bg-emerald-500 disabled:opacity-60 disabled:cursor-not-allowed text-white text-sm font-bold transition-all active:scale-[0.98] shadow-lg shadow-emerald-900/30"
              >
                <Loader2 v-if="saving" class="w-4 h-4 animate-spin" />
                <Check v-else class="w-4 h-4" />
                {{ saving ? 'Saving...' : 'Save Changes' }}
              </button>
            </div>

            <!-- View mode: Status update -->
            <div v-else>
              <p class="text-[10px] uppercase tracking-widest text-zinc-600 font-semibold mb-3">Update Status</p>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="status in ['Pending', 'Confirmed', 'In Progress', 'Ready', 'Delivered']"
                  :key="status"
                  @click="updateStatus(selectedOrder.id, status)"
                  :class="selectedOrder.status === status
                    ? 'bg-emerald-600 text-white border-emerald-500 shadow-lg shadow-emerald-900/30'
                    : 'bg-zinc-900 text-zinc-400 border-zinc-800 hover:border-zinc-600 hover:text-zinc-200'"
                  class="px-3 py-2 rounded-xl text-xs font-semibold border transition-all active:scale-95"
                >{{ status }}</button>
              </div>
            </div>

          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.modal-enter-active { transition: opacity 0.2s ease; }
.modal-enter-active .relative { transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); }
.modal-leave-active { transition: opacity 0.15s ease; }
.modal-leave-active .relative { transition: transform 0.15s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .relative { transform: translateY(40px); }
.modal-leave-to .relative { transform: translateY(20px); }

.slide-down-enter-active, .slide-down-leave-active { transition: all 0.2s ease; }
.slide-down-enter-from, .slide-down-leave-to { opacity: 0; transform: translateY(-6px); }

::-webkit-scrollbar { width: 4px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #3f3f46; border-radius: 4px; }

input[type="date"]::-webkit-calendar-picker-indicator { filter: invert(0.4); cursor: pointer; }

@media (max-width: 640px) {
  .modal-enter-from .relative,
  .modal-leave-to .relative { transform: translateY(100%); }
  .modal-enter-active .relative { transition: transform 0.35s cubic-bezier(0.22, 1, 0.36, 1); }
}
</style>