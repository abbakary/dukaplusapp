import React, { useState } from 'react';
import { 
  Truck, 
  Search, 
  Plus, 
  Phone, 
  Mail, 
  FileText, 
  CheckCircle2, 
  Clock, 
  Star, 
  Sparkles, 
  ArrowRight,
  PackagePlus,
  ArrowDownLeft,
  ArrowUpRight,
  Boxes,
  DollarSign,
  AlertCircle,
  Calendar,
  X,
  CreditCard,
  Printer,
  ChevronRight,
  ShieldCheck,
  Tag,
  Building2,
  Trash2
} from 'lucide-react';
import { 
  Language, 
  Supplier, 
  PurchaseOrder, 
  PurchaseOrderItem, 
  Product, 
  StockMovement, 
  SupplierPayment, 
  CalendarEvent,
  BusinessType,
} from '@/types/v1';
import { formatTSh, getTranslation } from '@/utils/translations';
import { ActionBar } from '@/components/v1/ActionBar';
import { CategoryTaxonomyPicker, type CategorySelection } from '@/components/v1/CategoryTaxonomyPicker';
import { ProductMetaBadges } from '@/components/v1/ProductMetaBadges';
import { DynamicProductForm, type DynamicProductFormValues } from '@/components/v1/DynamicProductForm';
import { getWorkplace } from '@/lib/businessProfiles';
import {
  getDefaultMainCategory,
  getDefaultUnit,
  getProductNamePlaceholder,
  getSupplierIndustryCategory,
  hasFeature,
} from '@/lib/businessEngine';
import confetti from 'canvas-confetti';
import { api } from '@/lib/api';
import { mapSupplier, mapPurchaseOrder, mapEvent, optionalApiDate, supplierToApiPayload, eventToApiPayload } from '@/lib/apiSync';

interface SuppliersViewProps {
  language: Language;
  suppliers: Supplier[];
  setSuppliers: React.Dispatch<React.SetStateAction<Supplier[]>>;
  purchaseOrders: PurchaseOrder[];
  setPurchaseOrders: React.Dispatch<React.SetStateAction<PurchaseOrder[]>>;
  products: Product[];
  setProducts: React.Dispatch<React.SetStateAction<Product[]>>;
  stockMovements: StockMovement[];
  setStockMovements: React.Dispatch<React.SetStateAction<StockMovement[]>>;
  supplierPayments?: SupplierPayment[];
  setSupplierPayments?: React.Dispatch<React.SetStateAction<SupplierPayment[]>>;
  events?: CalendarEvent[];
  setEvents?: React.Dispatch<React.SetStateAction<CalendarEvent[]>>;
  onOpenAIChatWithPrompt?: (prompt: string) => void;
  onReceivePO?: (poId: string) => void;
  businessType?: BusinessType;
}

function buildCustomItemDefaults(businessType: BusinessType, lang: 'sw' | 'en') {
  const showBatch = hasFeature(businessType, 'batch_tracking');
  const showExpiry = hasFeature(businessType, 'expiry_alerts');
  return {
    productName: '',
    category: getDefaultMainCategory(businessType, lang),
    sku: `SKU-${Date.now().toString().slice(-4)}`,
    quantity: 10,
    costPrice: 5000,
    sellingPrice: 8000,
    unit: getDefaultUnit(businessType),
    batchNumber: showBatch ? `BT-${new Date().getFullYear()}-N1` : '',
    expiryDate: showExpiry ? '2028-12-31' : '',
  };
}

export const SuppliersView: React.FC<SuppliersViewProps> = ({
  language,
  suppliers,
  setSuppliers,
  purchaseOrders,
  setPurchaseOrders,
  products,
  setProducts,
  stockMovements,
  setStockMovements,
  supplierPayments = [],
  setSupplierPayments,
  events = [],
  setEvents,
  onOpenAIChatWithPrompt,
  onReceivePO,
  businessType = 'retail',
}) => {
  const t = (key: any) => getTranslation(language, key);
  const isSw = language === 'sw';
  const lang = isSw ? 'sw' : 'en' as const;
  const workplace = getWorkplace(businessType);
  const showBatch = workplace.features?.batch_tracking ?? false;
  const showExpiry = workplace.features?.expiry_alerts ?? false;
  const productPlaceholder = getProductNamePlaceholder(businessType, lang);
  const defaultCategory = getDefaultMainCategory(businessType, lang);
  const supplierIndustry = getSupplierIndustryCategory(businessType, lang);

  // Active view tab: 'suppliers' | 'orders' | 'payments'
  const [activeSubTab, setActiveSubTab] = useState<'suppliers' | 'orders' | 'payments'>('orders');
  const [searchQuery, setSearchQuery] = useState('');
  const [orderStatusFilter, setOrderStatusFilter] = useState<string>('all');
  const [selectedSupplierId, setSelectedSupplierId] = useState<string>(suppliers[0]?.id || '');
  const [selectedPO, setSelectedPO] = useState<PurchaseOrder | null>(null);

  // Modals
  const [isCreatingPO, setIsCreatingPO] = useState(false);
  const [isAddingSupplier, setIsAddingSupplier] = useState(false);
  const [isRecordingPayment, setIsRecordingPayment] = useState(false);
  const [isViewGRNModalOpen, setIsViewGRNModalOpen] = useState(false);
  const [successToast, setSuccessToast] = useState<{ title: string; desc: string } | null>(null);

  // New Supplier Form
  const [newSupplier, setNewSupplier] = useState({
    name: '',
    contactPerson: '',
    phone: '+255 ',
    email: '',
    category: supplierIndustry,
    paymentTerms: 'Net 30 Days',
    leadTimeDays: 2,
    rating: 4.8,
  });

  // Payment to Supplier Form
  const [paymentForm, setPaymentForm] = useState({
    supplierId: suppliers[0]?.id || '',
    amount: 500000,
    paymentMethod: 'CRDB Bank Transfer',
    referenceNumber: `TXN-${Math.floor(100000 + Math.random() * 900000)}`,
    notes: 'Invoice settlement payment',
  });

  // Dynamic PO Builder Form State
  const [poForm, setPoForm] = useState<{
    supplierId: string;
    expectedDate: string;
    paymentTerms: string;
    paymentMethod: string;
    paymentStatus: 'paid' | 'credit' | 'partial';
    notes: string;
    items: PurchaseOrderItem[];
  }>({
    supplierId: suppliers[0]?.id || '',
    expectedDate: new Date(Date.now() + 2 * 86400000).toISOString().split('T')[0],
    paymentTerms: 'Net 30 Days',
    paymentMethod: 'bank_transfer',
    paymentStatus: 'credit',
    notes: '',
    items: [] as PurchaseOrderItem[],
  });

  // Temporary row state for adding to PO Form
  const [selectedExistingProdId, setSelectedExistingProdId] = useState<string>(products[0]?.id || '');
  const [isAddingNewCustomItem, setIsAddingNewCustomItem] = useState<boolean>(false);
  const [poCategorySel, setPoCategorySel] = useState<CategorySelection>({
    main: defaultCategory,
    displayPath: defaultCategory,
  });
  const [poDynamicFields, setPoDynamicFields] = useState<DynamicProductFormValues>({ metadata: {} });
  const [customItemForm, setCustomItemForm] = useState(() => buildCustomItemDefaults(businessType, lang));

  React.useEffect(() => {
    const nextCategory = getDefaultMainCategory(businessType, lang);
    setPoCategorySel({ main: nextCategory, displayPath: nextCategory });
    setCustomItemForm(buildCustomItemDefaults(businessType, lang));
    setNewSupplier(prev => ({ ...prev, category: getSupplierIndustryCategory(businessType, lang) }));
    setPoDynamicFields({ metadata: {} });
  }, [businessType, lang]);

  // Helper trigger toast
  const triggerToast = (title: string, desc: string) => {
    setSuccessToast({ title, desc });
    setTimeout(() => setSuccessToast(null), 6000);
  };

  // 1-CLICK RECEIVE & STOCK-IN HANDLER
  // Automatically creates new products, updates existing product stock and cost, logs stock movements,
  // updates supplier accounts payable, updates calendar events, and marks PO as received.
  const handleExecuteReceivePO = (targetPO: PurchaseOrder) => {
    if (targetPO.status === 'received') {
      alert('This Purchase Order has already been received and stocked into inventory.');
      return;
    }

    if (onReceivePO) {
      onReceivePO(targetPO.id);
      return;
    }

    const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 16);
    const todayDate = nowStr.split(' ')[0];
    let newProductsCount = 0;
    let existingProductsUpdated = 0;
    let totalStockAddedValuation = 0;

    const updatedProductList = [...products];
    const newStockMovements: StockMovement[] = [];

    targetPO.items.forEach(item => {
      const itemQty = Number(item.quantity);
      const itemCost = Number(item.costPrice);
      totalStockAddedValuation += itemQty * itemCost;

      // Check if product already exists in current inventory
      const existingIndex = updatedProductList.findIndex(
        p => (item.productId && p.id === item.productId) || (item.sku && p.sku.toLowerCase() === item.sku.toLowerCase()) || p.name.toLowerCase() === item.productName.toLowerCase()
      );

      if (existingIndex >= 0) {
        // Update existing product
        const existing = updatedProductList[existingIndex];
        const prevStock = existing.stock;
        const newStock = prevStock + itemQty;

        // Weighted Average Cost calculation
        const updatedCost = Math.round(((prevStock * existing.cost) + (itemQty * itemCost)) / (newStock || 1));

        updatedProductList[existingIndex] = {
          ...existing,
          stock: newStock,
          cost: updatedCost > 0 ? updatedCost : itemCost,
          price: item.sellingPrice && item.sellingPrice > 0 ? item.sellingPrice : existing.price,
          batchNumber: item.batchNumber || existing.batchNumber,
          expiryDate: item.expiryDate || existing.expiryDate,
        };

        existingProductsUpdated++;

        // Log Stock Movement
        newStockMovements.push({
          id: `sm-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
          date: nowStr,
          productId: existing.id,
          productName: existing.name,
          sku: existing.sku,
          type: 'in_purchase',
          quantity: itemQty,
          previousStock: prevStock,
          newStock: newStock,
          unitCost: itemCost,
          totalValuation: itemQty * itemCost,
          referenceId: targetPO.poNumber,
          referenceType: 'PO',
          operatorName: 'Store Manager (1-Click Auto Stock)',
          notes: `Stock-In from PO ${targetPO.poNumber} (${targetPO.supplierName})`,
        });
      } else {
        // Brand NEW Product introduced in this PO -> Automatically create and register!
        const newProdId = `prod-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`;
        const newProdObj: Product = {
          id: newProdId,
          name: item.productName,
          category: item.category || 'General',
          sku: item.sku || `SKU-${Math.floor(1000 + Math.random() * 9000)}`,
          price: item.sellingPrice || Math.round(itemCost * 1.4),
          cost: itemCost,
          stock: itemQty,
          reorderPoint: Math.max(5, Math.round(itemQty * 0.25)),
          unit: item.unit || getDefaultUnit(businessType),
          batchNumber: showBatch ? (item.batchNumber || `BT-${new Date().getFullYear()}`) : undefined,
          expiryDate: showExpiry ? (item.expiryDate || '2028-12-31') : undefined,
          businessType,
          requiresPrescription: false,
          ...(item.metadata ?? {}),
        } as Product;

        updatedProductList.unshift(newProdObj);
        newProductsCount++;

        // Log Stock Movement
        newStockMovements.push({
          id: `sm-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
          date: nowStr,
          productId: newProdId,
          productName: newProdObj.name,
          sku: newProdObj.sku,
          type: 'in_purchase',
          quantity: itemQty,
          previousStock: 0,
          newStock: itemQty,
          unitCost: itemCost,
          totalValuation: itemQty * itemCost,
          referenceId: targetPO.poNumber,
          referenceType: 'PO',
          operatorName: 'Store Manager (1-Click Auto Stock)',
          notes: `Initial Stock Creation from PO ${targetPO.poNumber} (${targetPO.supplierName})`,
        });
      }
    });

    // 1. Commit updated product inventory
    setProducts(updatedProductList);

    // 2. Commit stock movements
    setStockMovements(prev => [...newStockMovements, ...prev]);

    // 3. Update Purchase Order Status to 'received'
    setPurchaseOrders(prev => prev.map(po => {
      if (po.id === targetPO.id) {
        return {
          ...po,
          status: 'received',
          receivedDate: nowStr,
          receivedBy: 'Storekeeper / Mwenye Duka',
        };
      }
      return po;
    }));

    // 4. Update Supplier Payable Balance if purchased on credit terms
    if (targetPO.paymentStatus === 'credit' || (targetPO.totalAmount - (targetPO.paidAmount || 0)) > 0) {
      const remainingUnpaid = targetPO.totalAmount - (targetPO.paidAmount || 0);
      setSuppliers(prev => prev.map(s => {
        if (s.id === targetPO.supplierId) {
          return {
            ...s,
            outstandingPayable: s.outstandingPayable + remainingUnpaid,
          };
        }
        return s;
      }));
    }

    // 5. Complete matching calendar delivery event if present
    if (setEvents) {
      setEvents(prev => prev.map(e => {
        if (e.category === 'delivery' && (e.title.includes(targetPO.poNumber) || e.description.includes(targetPO.poNumber))) {
          return { ...e, completed: true };
        }
        return e;
      }));
    }

    // Celebratory Confetti & Toast
    confetti({
      particleCount: 60,
      spread: 70,
      origin: { y: 0.7 },
    });

    triggerToast(
      language === 'sw' ? 'Stoo Imesasishwa Kikamilifu!' : 'Inventory Auto-Stocked Successfully!',
      language === 'sw' 
        ? `Bidhaa ${existingProductsUpdated} zimeongezwa stoo, bidhaa mpya ${newProductsCount} zimeundwa kiotomatiki. Thamani: ${formatTSh(totalStockAddedValuation)}.`
        : `${existingProductsUpdated} existing items restocked, ${newProductsCount} new SKUs created. Total valuation added: ${formatTSh(totalStockAddedValuation)}.`
    );
  };

  // Add Item to Current PO Form
  const handleAddItemToPO = () => {
    if (isAddingNewCustomItem) {
      if (!customItemForm.productName) {
        alert('Please enter a product name');
        return;
      }

      const newItem: PurchaseOrderItem = {
        productName: customItemForm.productName,
        category: poCategorySel.displayPath || customItemForm.category,
        sku: customItemForm.sku,
        quantity: Number(customItemForm.quantity) || 1,
        costPrice: Number(customItemForm.costPrice) || 0,
        sellingPrice: Number(customItemForm.sellingPrice) || 0,
        unit: customItemForm.unit,
        batchNumber: showBatch ? customItemForm.batchNumber : undefined,
        expiryDate: showExpiry ? customItemForm.expiryDate : undefined,
        metadata: poDynamicFields.metadata,
        total: (Number(customItemForm.quantity) || 1) * (Number(customItemForm.costPrice) || 0),
        isNewProduct: true,
      };

      setPoForm(prev => ({
        ...prev,
        items: [...prev.items, newItem],
      }));

      setCustomItemForm(buildCustomItemDefaults(businessType, lang));
      setPoCategorySel({ main: defaultCategory, displayPath: defaultCategory });
      setPoDynamicFields({ metadata: {} });
      setIsAddingNewCustomItem(false);
    } else {
      const selectedProd = products.find(p => p.id === selectedExistingProdId);
      if (!selectedProd) return;

      const newItem: PurchaseOrderItem = {
        productId: selectedProd.id,
        productName: selectedProd.name,
        category: selectedProd.category,
        sku: selectedProd.sku,
        quantity: 20,
        costPrice: selectedProd.cost,
        sellingPrice: selectedProd.price,
        unit: selectedProd.unit,
        batchNumber: showBatch ? `BT-${new Date().getFullYear()}-${Math.floor(10 + Math.random() * 90)}` : undefined,
        expiryDate: showExpiry ? (selectedProd.expiryDate || '2028-12-31') : undefined,
        total: selectedProd.cost * 20,
        isNewProduct: false,
      };

      setPoForm(prev => ({
        ...prev,
        items: [...prev.items, newItem],
      }));
    }
  };

  // Remove item from PO form
  const handleRemovePOItem = (index: number) => {
    setPoForm(prev => ({
      ...prev,
      items: prev.items.filter((_, i) => i !== index),
    }));
  };

  // Save / Send New Purchase Order
  const handleSavePO = async (asStatus: 'draft' | 'sent') => {
    if (poForm.items.length === 0) {
      alert('Please add at least one line item to the purchase order.');
      return;
    }

    const targetSupplier = suppliers.find(s => s.id === poForm.supplierId) || suppliers[0];
    if (!targetSupplier) return;

    try {
      const raw = await api.createPurchaseOrder({
        supplier_id: targetSupplier.id,
        items: poForm.items.map(item => ({
          product_id: item.productId,
          product_name: item.productName,
          quantity: item.quantity,
          unit_cost: item.costPrice,
          total: item.costPrice * item.quantity,
          batch_number: item.batchNumber,
          expiry_date: optionalApiDate(item.expiryDate),
        })),
        notes: poForm.notes,
        expected_date: poForm.expectedDate,
      });
      const newPO = mapPurchaseOrder(raw as Record<string, unknown>);
      setPurchaseOrders(prev => [newPO, ...prev]);

      if (setEvents && asStatus === 'sent') {
        try {
          const evRaw = await api.createCalendarEvent(eventToApiPayload({
            title: `Supplier Delivery: ${targetSupplier.name} (${newPO.poNumber})`,
            category: 'delivery',
            date: poForm.expectedDate,
            time: '10:30',
            priority: 'high',
            description: `Expected delivery of ${poForm.items.length} items.`,
            assignedTo: 'Storekeeper',
          }));
          setEvents(prev => [mapEvent(evRaw as Record<string, unknown>), ...prev]);
        } catch { /* optional calendar sync */ }
      }

      setIsCreatingPO(false);
      triggerToast(
        language === 'sw' ? 'Agizo la Bidhaa Limeundwa!' : 'Purchase Order Created!',
        `PO ${newPO.poNumber} for ${targetSupplier.name} saved to server.`
      );
    } catch (err) {
      alert((err as Error).message);
    }
  };

  // Add Supplier
  const handleSaveNewSupplier = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSupplier.name) return;

    try {
      const raw = await api.createSupplier(supplierToApiPayload({
        name: newSupplier.name,
        contactPerson: newSupplier.contactPerson || 'Sales Representative',
        phone: newSupplier.phone,
        email: newSupplier.email,
        category: newSupplier.category,
        paymentTerms: newSupplier.paymentTerms,
        leadTimeDays: Number(newSupplier.leadTimeDays) || 2,
        rating: Number(newSupplier.rating) || 4.8,
      }));
      const createdSupplier = mapSupplier(raw as Record<string, unknown>);
      setSuppliers(prev => [createdSupplier, ...prev]);
      setIsAddingSupplier(false);
      setSelectedSupplierId(createdSupplier.id);
      triggerToast(
        language === 'sw' ? 'Msambazaji Amesajiliwa' : 'Supplier Registered',
        `${createdSupplier.name} added to your supplier database.`
      );
    } catch (err) {
      alert((err as Error).message);
    }
  };

  // Record Payment to Supplier
  const handleSavePayment = (e: React.FormEvent) => {
    e.preventDefault();
    const sup = suppliers.find(s => s.id === paymentForm.supplierId);
    if (!sup) return;

    const amt = Number(paymentForm.amount);
    const balanceBefore = sup.outstandingPayable;
    const balanceAfter = Math.max(0, balanceBefore - amt);

    const paymentRecord: SupplierPayment = {
      id: `sp-${Date.now()}`,
      supplierId: sup.id,
      supplierName: sup.name,
      date: new Date().toISOString().replace('T', ' ').substring(0, 16),
      amount: amt,
      paymentMethod: paymentForm.paymentMethod,
      referenceNumber: paymentForm.referenceNumber,
      notes: paymentForm.notes,
      balanceBefore,
      balanceAfter,
    };

    if (setSupplierPayments) {
      setSupplierPayments(prev => [paymentRecord, ...prev]);
    }

    // update supplier payable
    setSuppliers(prev => prev.map(s => {
      if (s.id === sup.id) {
        return { ...s, outstandingPayable: balanceAfter };
      }
      return s;
    }));

    setIsRecordingPayment(false);
    triggerToast(
      language === 'sw' ? 'Malipo Yamerekodiwa' : 'Payment Recorded',
      `${formatTSh(amt)} paid to ${sup.name}. New ledger balance: ${formatTSh(balanceAfter)}.`
    );
  };

  // Filtered lists
  const filteredSuppliers = suppliers.filter(s =>
    s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredPOs = purchaseOrders.filter(po => {
    const matchesSearch = po.poNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      po.supplierName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      po.items.some(i => i.productName.toLowerCase().includes(searchQuery.toLowerCase()));
    
    if (orderStatusFilter === 'all') return matchesSearch;
    return matchesSearch && po.status === orderStatusFilter;
  });

  const selectedSupplier = suppliers.find(s => s.id === selectedSupplierId) || suppliers[0];

  // Total calculations
  const totalPayables = suppliers.reduce((sum, s) => sum + s.outstandingPayable, 0);
  const pendingDeliveryCount = purchaseOrders.filter(po => po.status === 'sent').length;
  const receivedOrdersCount = purchaseOrders.filter(po => po.status === 'received').length;

  return (
    <div className="space-y-6 pb-16">
      {/* Toast Notification */}
      {successToast && (
        <div className="p-4 bg-emerald-50 border border-emerald-300 rounded-xl text-emerald-900 shadow-sm flex items-start gap-3 animate-in fade-in slide-in-from-top-2 duration-200">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-xs">{successToast.title}</div>
            <div className="text-[11px] text-emerald-700 mt-0.5">{successToast.desc}</div>
          </div>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-[#323130] tracking-tight">{t('suppliers')} & {t('purchaseOrders')}</h2>
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#6264A7]/10 text-[#6264A7] border border-[#6264A7]/20">
              Connected Hub
            </span>
          </div>
          <p className="text-xs text-[#605E5C] mt-0.5">
            1-Click Automated Inward Stocking • Dynamic PO Builder • Live Inventory & Payables Sync
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            id="btn-create-po-top"
            onClick={() => setIsCreatingPO(true)}
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-[#6264A7] hover:bg-[#555793] text-white text-xs font-semibold shadow-xs transition-all active:scale-95 cursor-pointer"
          >
            <PackagePlus className="w-4 h-4" />
            <span>{t('createPO')}</span>
          </button>

          <button
            onClick={() => setIsAddingSupplier(true)}
            className="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-white hover:bg-[#F3F2F1] text-[#323130] text-xs font-semibold border border-[#E1DFDD] transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4 text-[#0078D4]" />
            <span>Add Supplier</span>
          </button>
        </div>
      </div>

      {/* KPI Overview Tiles */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Total Accounts Payable</div>
          <div className="text-xl font-extrabold text-[#D13438] mt-1">{formatTSh(totalPayables)}</div>
          <div className="text-[11px] text-[#605E5C] mt-1 flex items-center justify-between">
            <span>Across {suppliers.length} suppliers</span>
            <button 
              onClick={() => setIsRecordingPayment(true)}
              className="text-[#0078D4] font-bold hover:underline cursor-pointer"
            >
              Pay Now →
            </button>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Pending Deliveries</div>
          <div className="text-xl font-extrabold text-amber-600 mt-1">{pendingDeliveryCount} Orders</div>
          <div className="text-[11px] text-[#605E5C] mt-1">Ready for 1-Click Stock-In</div>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Received & Stocked</div>
          <div className="text-xl font-extrabold text-[#107C10] mt-1">{receivedOrdersCount} Fulfilled</div>
          <div className="text-[11px] text-[#107C10] font-semibold mt-1">✓ Verified in Inventory</div>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Avg Delivery Lead Time</div>
          <div className="text-xl font-extrabold text-[#6264A7] mt-1">1.8 Days</div>
          <div className="text-[11px] text-[#107C10] font-semibold mt-1">Dar es Salaam region fast-dispatch</div>
        </div>
      </div>

      {/* Sub-Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#EDEBE9] pb-2">
        <button
          onClick={() => setActiveSubTab('orders')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
            activeSubTab === 'orders'
              ? 'bg-[#6264A7] text-white shadow-xs'
              : 'bg-white text-[#605E5C] hover:bg-[#F3F2F1] border border-[#E1DFDD]'
          }`}
        >
          <FileText className="w-4 h-4" />
          <span>{t('purchaseOrders')} ({purchaseOrders.length})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('suppliers')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
            activeSubTab === 'suppliers'
              ? 'bg-[#6264A7] text-white shadow-xs'
              : 'bg-white text-[#605E5C] hover:bg-[#F3F2F1] border border-[#E1DFDD]'
          }`}
        >
          <Building2 className="w-4 h-4" />
          <span>Suppliers Directory ({suppliers.length})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('payments')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
            activeSubTab === 'payments'
              ? 'bg-[#6264A7] text-white shadow-xs'
              : 'bg-white text-[#605E5C] hover:bg-[#F3F2F1] border border-[#E1DFDD]'
          }`}
        >
          <CreditCard className="w-4 h-4" />
          <span>Supplier Payables & Payments ({supplierPayments.length})</span>
        </button>
      </div>

      {/* ACTION BAR */}
      <ActionBar
        language={language}
        onAdd={() => {
          if (activeSubTab === 'orders') setIsCreatingPO(true);
          else if (activeSubTab === 'suppliers') setIsAddingSupplier(true);
          else setIsRecordingPayment(true);
        }}
        onAISuggest={() => {
          if (onOpenAIChatWithPrompt) {
            onOpenAIChatWithPrompt('Toa uchambuzi wa bei za wasambazaji, muda wa kuagiza bidhaa za dawa, na utengeneze orodha ya agizo jipya la ununuzi kulingana na bidhaa zilizopungua stoo.');
          }
        }}
        onExport={() => alert('Exporting Procurement & Inward Stock Ledger (Excel/PDF)...')}
        customAddLabel={activeSubTab === 'orders' ? '➕ Create PO' : activeSubTab === 'suppliers' ? '➕ Add Supplier' : '➕ Record Payment'}
        selectedCount={selectedPO ? 1 : 0}
        totalCount={activeSubTab === 'orders' ? purchaseOrders.length : suppliers.length}
      />

      {/* ================= TAB 1: PURCHASE ORDERS (CORE WORKFLOW) ================= */}
      {activeSubTab === 'orders' && (
        <div className="space-y-4">
          {/* Filter Bar */}
          <div className="bg-white rounded-xl p-3 border border-[#E1DFDD] shadow-xs flex flex-wrap items-center justify-between gap-3">
            <div className="relative flex-1 min-w-[260px] max-w-md">
              <Search className="w-4 h-4 text-[#605E5C] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search PO #, supplier name, or item..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-1.5 text-xs bg-[#F3F2F1] border border-transparent focus:border-[#0078D4] focus:bg-white rounded-lg outline-none"
              />
            </div>

            <div className="flex items-center gap-1.5 text-xs font-semibold">
              <button
                onClick={() => setOrderStatusFilter('all')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  orderStatusFilter === 'all' ? 'bg-[#6264A7] text-white' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                All POs ({purchaseOrders.length})
              </button>
              <button
                onClick={() => setOrderStatusFilter('sent')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  orderStatusFilter === 'sent' ? 'bg-amber-600 text-white' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                ⏳ Pending Delivery ({purchaseOrders.filter(p => p.status === 'sent').length})
              </button>
              <button
                onClick={() => setOrderStatusFilter('received')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  orderStatusFilter === 'received' ? 'bg-[#107C10] text-white' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                ✓ Received & Stocked ({purchaseOrders.filter(p => p.status === 'received').length})
              </button>
              <button
                onClick={() => setOrderStatusFilter('draft')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  orderStatusFilter === 'draft' ? 'bg-[#605E5C] text-white' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                Drafts ({purchaseOrders.filter(p => p.status === 'draft').length})
              </button>
            </div>
          </div>

          {/* Orders Table */}
          <div className="bg-white rounded-xl border border-[#E1DFDD] shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#F8F8F8] border-b border-[#EDEBE9] text-[#605E5C] font-bold uppercase tracking-wider">
                  <tr>
                    <th className="py-3 px-4">PO Number & Date</th>
                    <th className="py-3 px-3">Supplier Partner</th>
                    <th className="py-3 px-3">Items Ordered</th>
                    <th className="py-3 px-3">Expected Delivery</th>
                    <th className="py-3 px-3">Total Amount</th>
                    <th className="py-3 px-3">Status</th>
                    <th className="py-3 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F2F1]">
                  {filteredPOs.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="text-center py-10 text-xs text-[#605E5C]">
                        No purchase orders found matching criteria.
                      </td>
                    </tr>
                  ) : (
                    filteredPOs.map(po => {
                      const isPending = po.status === 'sent';
                      const isReceived = po.status === 'received';

                      return (
                        <tr 
                          key={po.id}
                          className="hover:bg-[#FAF9F8] transition-colors"
                        >
                          <td className="py-3 px-4">
                            <div className="font-bold text-[#0078D4] font-mono">{po.poNumber}</div>
                            <div className="text-[10px] text-[#605E5C]">{po.dateCreated}</div>
                          </td>

                          <td className="py-3 px-3">
                            <div className="font-bold text-[#323130]">{po.supplierName}</div>
                            <div className="text-[10px] text-[#605E5C]">{po.paymentTerms}</div>
                          </td>

                          <td className="py-3 px-3">
                            <div className="font-semibold text-[#323130]">
                              {po.items.length} line items ({po.items.reduce((s, i) => s + i.quantity, 0)} units)
                            </div>
                            <div className="text-[10px] text-[#605E5C] truncate max-w-[200px]">
                              {po.items.map(i => i.productName).join(', ')}
                            </div>
                          </td>

                          <td className="py-3 px-3 font-mono">
                            <div className="text-[#323130] font-medium">{po.expectedDate}</div>
                            {isReceived && (
                              <div className="text-[10px] text-[#107C10] font-semibold flex items-center gap-1">
                                <CheckCircle2 className="w-3 h-3 text-[#107C10]" /> Received on {po.receivedDate?.split(' ')[0]}
                              </div>
                            )}
                          </td>

                          <td className="py-3 px-3">
                            <div className="font-extrabold text-[#323130]">{formatTSh(po.totalAmount)}</div>
                            <div className="text-[10px] text-[#605E5C]">
                              {po.paymentStatus === 'paid' ? '✓ Paid in Full' : 'Unsettled Credit'}
                            </div>
                          </td>

                          <td className="py-3 px-3">
                            <span className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full ${
                              isReceived
                                ? 'bg-[#107C10]/10 text-[#107C10] border border-[#107C10]/30'
                                : isPending
                                ? 'bg-amber-100 text-amber-900 border border-amber-300'
                                : 'bg-[#EDEBE9] text-[#605E5C]'
                            }`}>
                              {isReceived ? '✓ Stocked in Inventory' : isPending ? '⏳ Awaiting Delivery' : 'Draft'}
                            </span>
                          </td>

                          <td className="py-3 px-4 text-right">
                            <div className="flex items-center justify-end gap-2">
                              {/* 1-CLICK RECEIVE & STOCK-IN BUTTON */}
                              {isPending && (
                                <button
                                  id={`btn-receive-po-${po.id}`}
                                  onClick={() => handleExecuteReceivePO(po)}
                                  className="px-3 py-1.5 rounded-lg bg-[#107C10] hover:bg-[#0E6A0E] text-white font-bold text-xs flex items-center gap-1 shadow-xs transition-all active:scale-95 cursor-pointer"
                                  title="1-Click Automatic Stock-In & Inventory Update"
                                >
                                  <PackagePlus className="w-3.5 h-3.5" />
                                  <span>Receive & Stock In</span>
                                </button>
                              )}

                              <button
                                onClick={() => {
                                  setSelectedPO(po);
                                  setIsViewGRNModalOpen(true);
                                }}
                                className="px-2.5 py-1.5 rounded-lg bg-[#F3F2F1] hover:bg-[#EDEBE9] text-[#323130] font-semibold text-xs transition-colors cursor-pointer"
                                title="View Goods Received Note & Invoice"
                              >
                                <FileText className="w-3.5 h-3.5 text-[#6264A7]" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ================= TAB 2: SUPPLIERS DIRECTORY ================= */}
      {activeSubTab === 'suppliers' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-3">
            <div className="relative">
              <Search className="w-4 h-4 text-[#605E5C] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search supplier name or category..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-xs bg-white border border-[#E1DFDD] rounded-xl outline-none"
              />
            </div>

            <div className="space-y-3">
              {filteredSuppliers.map(sup => {
                const isSelected = sup.id === selectedSupplierId;
                return (
                  <div
                    key={sup.id}
                    onClick={() => setSelectedSupplierId(sup.id)}
                    className={`p-4 bg-white rounded-xl border transition-all cursor-pointer ${
                      isSelected ? 'border-[#6264A7] ring-1 ring-[#6264A7] shadow-xs' : 'border-[#E1DFDD] hover:border-[#C8C6C4]'
                    }`}
                  >
                    <div className="flex flex-wrap items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-[#6264A7]/10 text-[#6264A7] flex items-center justify-center font-bold">
                          <Building2 className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="text-sm font-bold text-[#323130]">{sup.name}</h4>
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 flex items-center gap-0.5">
                              <Star className="w-3 h-3 fill-emerald-600 text-emerald-600" /> {sup.rating}
                            </span>
                          </div>
                          <p className="text-xs text-[#605E5C]">{sup.category} • {sup.contactPerson}</p>
                        </div>
                      </div>

                      <div className="text-right text-xs">
                        <div className="font-semibold text-[#605E5C]">Payable Balance</div>
                        <div className="font-extrabold text-[#D13438]">{formatTSh(sup.outstandingPayable)}</div>
                      </div>
                    </div>

                    <div className="mt-3 pt-3 border-t border-[#F3F2F1] flex flex-wrap items-center justify-between text-xs text-[#605E5C] gap-2">
                      <div className="flex items-center gap-4">
                        <span className="flex items-center gap-1"><Phone className="w-3.5 h-3.5 text-[#0078D4]" /> {sup.phone}</span>
                        <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5 text-amber-600" /> {sup.leadTimeDays} days lead time</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold px-2 py-0.5 rounded bg-[#F3F2F1] text-[#323130]">{sup.paymentTerms}</span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setPoForm(prev => ({ ...prev, supplierId: sup.id }));
                            setIsCreatingPO(true);
                          }}
                          className="px-2.5 py-1 rounded bg-[#6264A7] text-white font-bold text-[11px] hover:bg-[#555793] cursor-pointer"
                        >
                          + Order
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Selected Supplier Details Panel */}
          <div>
            {selectedSupplier && (
              <div className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs space-y-4 sticky top-4">
                <div className="border-b border-[#F3F2F1] pb-3">
                  <span className="text-[10px] uppercase font-bold text-[#6264A7]">Selected Partner Profile</span>
                  <h3 className="text-base font-bold text-[#323130] mt-0.5">{selectedSupplier.name}</h3>
                  <p className="text-xs text-[#605E5C]">{selectedSupplier.contactPerson} • {selectedSupplier.email}</p>
                </div>

                <div className="space-y-2 text-xs">
                  <div className="flex justify-between p-2.5 rounded bg-[#FAF9F8]">
                    <span className="text-[#605E5C]">Payment Terms:</span>
                    <span className="font-bold text-[#323130]">{selectedSupplier.paymentTerms}</span>
                  </div>
                  <div className="flex justify-between p-2.5 rounded bg-[#FAF9F8]">
                    <span className="text-[#605E5C]">Lead Time:</span>
                    <span className="font-bold text-[#323130]">{selectedSupplier.leadTimeDays} Business Days</span>
                  </div>
                  <div className="flex justify-between p-2.5 rounded bg-[#FAF9F8]">
                    <span className="text-[#605E5C]">Total Outstanding Debt:</span>
                    <span className="font-bold text-[#D13438]">{formatTSh(selectedSupplier.outstandingPayable)}</span>
                  </div>
                </div>

                <div className="space-y-2 pt-2">
                  <button
                    onClick={() => {
                      setPoForm(prev => ({ ...prev, supplierId: selectedSupplier.id }));
                      setIsCreatingPO(true);
                    }}
                    className="w-full py-2.5 rounded-xl bg-[#6264A7] hover:bg-[#555793] text-white font-bold text-xs flex items-center justify-center gap-2 shadow-xs transition-all cursor-pointer"
                  >
                    <PackagePlus className="w-4 h-4" />
                    <span>Create Purchase Order</span>
                  </button>

                  <button
                    onClick={() => {
                      setPaymentForm(prev => ({ ...prev, supplierId: selectedSupplier.id }));
                      setIsRecordingPayment(true);
                    }}
                    className="w-full py-2.5 rounded-xl bg-white hover:bg-[#F3F2F1] text-[#323130] border border-[#E1DFDD] font-bold text-xs flex items-center justify-center gap-2 transition-all cursor-pointer"
                  >
                    <CreditCard className="w-4 h-4 text-[#0078D4]" />
                    <span>Record Payment Settlement</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ================= TAB 3: SUPPLIER PAYMENTS & PAYABLES LEDGER ================= */}
      {activeSubTab === 'payments' && (
        <div className="space-y-4">
          <div className="flex justify-between items-center bg-white p-4 rounded-xl border border-[#E1DFDD] shadow-xs">
            <div>
              <h3 className="font-bold text-sm text-[#323130]">Supplier Settlement History & Outward Payments</h3>
              <p className="text-xs text-[#605E5C]">Tracks Bank Transfers, M-Pesa, and Cash remittances to distributors</p>
            </div>
            <button
              onClick={() => setIsRecordingPayment(true)}
              className="px-4 py-2 rounded-lg bg-[#6264A7] text-white font-bold text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Record New Payment</span>
            </button>
          </div>

          <div className="bg-white rounded-xl border border-[#E1DFDD] shadow-xs overflow-hidden">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#F8F8F8] border-b border-[#EDEBE9] text-[#605E5C] font-bold uppercase">
                <tr>
                  <th className="py-3 px-4">Date & Time</th>
                  <th className="py-3 px-3">Supplier Name</th>
                  <th className="py-3 px-3">Payment Method</th>
                  <th className="py-3 px-3">Reference / Txn ID</th>
                  <th className="py-3 px-3">Amount Paid</th>
                  <th className="py-3 px-3">Balance After</th>
                  <th className="py-3 px-4">Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#F3F2F1]">
                {supplierPayments.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="text-center py-8 text-xs text-[#605E5C]">
                      No supplier payments recorded yet.
                    </td>
                  </tr>
                ) : (
                  supplierPayments.map(sp => (
                    <tr key={sp.id} className="hover:bg-[#FAF9F8]">
                      <td className="py-3 px-4 font-mono text-[#605E5C]">{sp.date}</td>
                      <td className="py-3 px-3 font-bold text-[#323130]">{sp.supplierName}</td>
                      <td className="py-3 px-3 font-semibold text-[#0078D4]">{sp.paymentMethod}</td>
                      <td className="py-3 px-3 font-mono text-[#605E5C]">{sp.referenceNumber}</td>
                      <td className="py-3 px-3 font-extrabold text-[#107C10]">{formatTSh(sp.amount)}</td>
                      <td className="py-3 px-3 font-mono text-[#D13438]">{formatTSh(sp.balanceAfter)}</td>
                      <td className="py-3 px-4 text-[#605E5C]">{sp.notes || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ================= MODAL 1: INTERACTIVE PURCHASE ORDER CREATOR ================= */}
      {isCreatingPO && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-white rounded-2xl max-w-3xl w-full border border-[#E1DFDD] shadow-2xl p-6 space-y-5 my-8">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#6264A7]/10 text-[#6264A7] flex items-center justify-center">
                  <PackagePlus className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-[#323130]">Create Purchase Order (Agizo la Ununuzi)</h3>
                  <p className="text-[11px] text-[#605E5C]">Add items, set costs, and auto-sync to inventory & calendar</p>
                </div>
              </div>
              <button onClick={() => setIsCreatingPO(false)} className="text-[#605E5C] hover:text-black">
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* PO Header Meta */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
              <div>
                <label className="block font-bold text-[#323130] mb-1">Select Supplier *</label>
                <select
                  value={poForm.supplierId}
                  onChange={e => setPoForm({ ...poForm, supplierId: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] border border-[#EDEBE9] rounded-lg font-medium outline-none focus:bg-white focus:border-[#0078D4]"
                >
                  {suppliers.map(s => (
                    <option key={s.id} value={s.id}>{s.name} ({s.paymentTerms})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-[#323130] mb-1">Expected Delivery Date *</label>
                <input
                  type="date"
                  value={poForm.expectedDate}
                  onChange={e => setPoForm({ ...poForm, expectedDate: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] border border-[#EDEBE9] rounded-lg font-medium outline-none focus:bg-white focus:border-[#0078D4]"
                />
              </div>

              <div>
                <label className="block font-bold text-[#323130] mb-1">Payment Status</label>
                <select
                  value={poForm.paymentStatus}
                  onChange={e => setPoForm({ ...poForm, paymentStatus: e.target.value as any })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] border border-[#EDEBE9] rounded-lg font-medium outline-none focus:bg-white focus:border-[#0078D4]"
                >
                  <option value="credit">Buy on Supplier Credit (Net Terms)</option>
                  <option value="paid">Paid Upfront (Cash / Bank)</option>
                </select>
              </div>
            </div>

            {/* Add Line Item Box */}
            <div className="p-4 bg-[#F8F8F8] rounded-xl border border-[#EDEBE9] space-y-3">
              <div className="flex items-center justify-between">
                <span className="font-bold text-xs text-[#323130]">Add Item to Order</span>
                <div className="flex items-center gap-2 text-xs">
                  <button
                    type="button"
                    onClick={() => setIsAddingNewCustomItem(false)}
                    className={`px-2.5 py-1 rounded-md font-semibold transition-all ${
                      !isAddingNewCustomItem ? 'bg-[#6264A7] text-white shadow-xs' : 'bg-[#EDEBE9] text-[#605E5C]'
                    }`}
                  >
                    Select Existing Product
                  </button>
                  <button
                    type="button"
                    onClick={() => setIsAddingNewCustomItem(true)}
                    className={`px-2.5 py-1 rounded-md font-semibold transition-all ${
                      isAddingNewCustomItem ? 'bg-[#0078D4] text-white shadow-xs' : 'bg-[#EDEBE9] text-[#605E5C]'
                    }`}
                  >
                    ✨ Introduce New Product
                  </button>
                </div>
              </div>

              {!isAddingNewCustomItem ? (
                <div className="flex flex-wrap items-end gap-3 text-xs">
                  <div className="flex-1 min-w-[200px]">
                    <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">Product from Inventory</label>
                    <select
                      value={selectedExistingProdId}
                      onChange={e => setSelectedExistingProdId(e.target.value)}
                      className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                    >
                      {products.map(p => (
                        <option key={p.id} value={p.id}>
                          {p.name} (Current Stock: {p.stock} | Cost: {formatTSh(p.cost)})
                        </option>
                      ))}
                    </select>
                  </div>
                  <button
                    type="button"
                    onClick={handleAddItemToPO}
                    className="px-4 py-1.5 bg-[#6264A7] text-white font-bold rounded-lg hover:bg-[#555793] cursor-pointer"
                  >
                    + Add Line
                  </button>
                </div>
              ) : (
                <div className="space-y-3 text-xs">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">
                        {isSw ? 'Jina la Bidhaa *' : 'New Product Name *'}
                      </label>
                      <input
                        type="text"
                        placeholder={productPlaceholder}
                        value={customItemForm.productName}
                        onChange={e => setCustomItemForm({ ...customItemForm, productName: e.target.value })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                    <div>
                      <CategoryTaxonomyPicker
                        language={language}
                        businessType={businessType}
                        value={poCategorySel}
                        onChange={(sel) => {
                          setPoCategorySel(sel);
                          setCustomItemForm({ ...customItemForm, category: sel.displayPath });
                        }}
                      />
                    </div>
                  </div>

                  <DynamicProductForm
                    language={language}
                    businessType={businessType}
                    values={poDynamicFields}
                    onChange={setPoDynamicFields}
                  />

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">SKU / Code</label>
                      <input
                        type="text"
                        value={customItemForm.sku}
                        onChange={e => setCustomItemForm({ ...customItemForm, sku: e.target.value })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">{isSw ? 'Kipimo' : 'Unit'}</label>
                      <select
                        value={customItemForm.unit}
                        onChange={e => setCustomItemForm({ ...customItemForm, unit: e.target.value })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      >
                        {workplace.default_units.map(u => <option key={u} value={u}>{u}</option>)}
                      </select>
                    </div>
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">{isSw ? 'Idadi' : 'Qty Ordered'}</label>
                      <input
                        type="number"
                        value={customItemForm.quantity}
                        onChange={e => setCustomItemForm({ ...customItemForm, quantity: Number(e.target.value) })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">{isSw ? 'Gharama (TSh)' : 'Unit Cost (TSh)'}</label>
                      <input
                        type="number"
                        value={customItemForm.costPrice}
                        onChange={e => setCustomItemForm({ ...customItemForm, costPrice: Number(e.target.value) })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">{isSw ? 'Bei ya Uuzaji (TSh)' : 'Selling Price (TSh)'}</label>
                      <input
                        type="number"
                        value={customItemForm.sellingPrice}
                        onChange={e => setCustomItemForm({ ...customItemForm, sellingPrice: Number(e.target.value) })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                    {showBatch && (
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">{isSw ? 'Batch #' : 'Batch #'}</label>
                      <input
                        type="text"
                        value={customItemForm.batchNumber}
                        onChange={e => setCustomItemForm({ ...customItemForm, batchNumber: e.target.value })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                    )}
                    {showExpiry && (
                    <div>
                      <label className="block text-[11px] font-semibold text-[#605E5C] mb-1">{isSw ? 'Tarehe ya Mwisho' : 'Expiry Date'}</label>
                      <input
                        type="date"
                        value={customItemForm.expiryDate}
                        onChange={e => setCustomItemForm({ ...customItemForm, expiryDate: e.target.value })}
                        className="w-full px-3 py-1.5 bg-white border border-[#C8C6C4] rounded-lg outline-none"
                      />
                    </div>
                    )}
                  </div>

                  <div className="flex justify-end pt-1">
                    <button
                      type="button"
                      onClick={handleAddItemToPO}
                      className="px-4 py-1.5 bg-[#0078D4] text-white font-bold rounded-lg hover:bg-[#106EBE] cursor-pointer"
                    >
                      + Add New Product to PO
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Current PO Line Items Table */}
            <div className="border border-[#E1DFDD] rounded-xl overflow-hidden">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#F8F8F8] text-[#605E5C] font-bold border-b border-[#EDEBE9]">
                  <tr>
                    <th className="py-2.5 px-3">Item Description</th>
                    <th className="py-2.5 px-3">Quantity</th>
                    <th className="py-2.5 px-3">Cost (TSh)</th>
                    <th className="py-2.5 px-3">Selling Price</th>
                    <th className="py-2.5 px-3 font-bold text-right">Line Total</th>
                    <th className="py-2.5 px-2 text-center">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F2F1]">
                  {poForm.items.map((item, idx) => (
                    <tr key={idx}>
                      <td className="py-2.5 px-3">
                        <div className="font-bold text-[#323130] flex items-center gap-1.5">
                          {item.productName}
                          {item.isNewProduct && (
                            <span className="text-[9px] px-1.5 py-0.2 rounded bg-blue-100 text-blue-800 font-bold">NEW</span>
                          )}
                        </div>
                        <div className="text-[10px] text-[#605E5C]">
                          SKU: {item.sku || 'N/A'}
                          {showBatch && item.batchNumber ? ` • Batch: ${item.batchNumber}` : ''}
                          {showExpiry && item.expiryDate ? ` • Exp: ${item.expiryDate}` : ''}
                        </div>
                        {item.metadata && Object.keys(item.metadata).length > 0 && (
                          <ProductMetaBadges
                            product={{
                              id: item.productId ?? `po-${idx}`,
                              name: item.productName,
                              category: item.category ?? '',
                              sku: item.sku ?? '',
                              price: item.sellingPrice ?? 0,
                              cost: item.costPrice,
                              stock: 0,
                              reorderPoint: 0,
                              unit: item.unit ?? 'pcs',
                              businessType,
                              ...item.metadata,
                            } as Product}
                            businessType={businessType}
                            language={language}
                            max={4}
                            className="mt-1"
                          />
                        )}
                      </td>

                      <td className="py-2.5 px-3">
                        <input
                          type="number"
                          min="1"
                          value={item.quantity}
                          onChange={e => {
                            const val = Number(e.target.value) || 1;
                            const newItems = [...poForm.items];
                            newItems[idx].quantity = val;
                            newItems[idx].total = val * newItems[idx].costPrice;
                            setPoForm({ ...poForm, items: newItems });
                          }}
                          className="w-16 px-2 py-1 bg-[#F3F2F1] rounded text-center font-bold"
                        />
                      </td>

                      <td className="py-2.5 px-3">
                        <input
                          type="number"
                          value={item.costPrice}
                          onChange={e => {
                            const val = Number(e.target.value) || 0;
                            const newItems = [...poForm.items];
                            newItems[idx].costPrice = val;
                            newItems[idx].total = newItems[idx].quantity * val;
                            setPoForm({ ...poForm, items: newItems });
                          }}
                          className="w-24 px-2 py-1 bg-[#F3F2F1] rounded font-bold"
                        />
                      </td>

                      <td className="py-2.5 px-3 font-mono text-[#0078D4]">
                        {formatTSh(item.sellingPrice || item.costPrice * 1.3)}
                      </td>

                      <td className="py-2.5 px-3 font-extrabold text-[#323130] text-right font-mono">
                        {formatTSh(item.costPrice * item.quantity)}
                      </td>

                      <td className="py-2.5 px-2 text-center">
                        <button
                          type="button"
                          onClick={() => handleRemovePOItem(idx)}
                          className="text-[#D13438] hover:bg-rose-50 p-1 rounded cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              <div className="p-3 bg-[#FAF9F8] border-t border-[#EDEBE9] flex justify-between items-center text-xs">
                <span className="font-semibold text-[#605E5C]">
                  Total {poForm.items.length} line items ({poForm.items.reduce((s, i) => s + i.quantity, 0)} units)
                </span>
                <div className="text-right">
                  <span className="text-[#605E5C] text-[11px] mr-2">Total PO Valuation:</span>
                  <span className="text-base font-extrabold text-[#323130] font-mono">
                    {formatTSh(poForm.items.reduce((s, i) => s + (i.costPrice * i.quantity), 0))}
                  </span>
                </div>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex items-center justify-between pt-2 border-t border-[#EDEBE9]">
              <button
                type="button"
                onClick={() => setIsCreatingPO(false)}
                className="px-4 py-2 rounded-lg text-xs font-semibold text-[#605E5C] bg-[#F3F2F1] hover:bg-[#EDEBE9] cursor-pointer"
              >
                {t('cancel')}
              </button>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => handleSavePO('draft')}
                  className="px-4 py-2 rounded-lg text-xs font-semibold text-[#323130] bg-white border border-[#C8C6C4] hover:bg-[#F3F2F1] cursor-pointer"
                >
                  Save as Draft
                </button>
                <button
                  type="button"
                  onClick={() => handleSavePO('sent')}
                  className="px-5 py-2 rounded-lg text-xs font-bold text-white bg-[#6264A7] hover:bg-[#555793] shadow-xs cursor-pointer"
                >
                  Send & Order from Supplier →
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ================= MODAL 2: VIEW GRN / PURCHASE ORDER DETAILS ================= */}
      {isViewGRNModalOpen && selectedPO && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full border border-[#E1DFDD] shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <div className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-[#6264A7]" />
                <div>
                  <h3 className="font-bold text-base text-[#323130]">{selectedPO.poNumber} — Goods Received Note</h3>
                  <p className="text-[11px] text-[#605E5C]">{selectedPO.supplierName}</p>
                </div>
              </div>
              <button onClick={() => setIsViewGRNModalOpen(false)} className="text-[#605E5C]">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs p-3 bg-[#FAF9F8] rounded-xl border border-[#EDEBE9]">
              <div>
                <div className="text-[#605E5C]">Status:</div>
                <div className="font-bold text-[#323130] uppercase">{selectedPO.status}</div>
              </div>
              <div>
                <div className="text-[#605E5C]">Order Date:</div>
                <div className="font-mono text-[#323130]">{selectedPO.dateCreated}</div>
              </div>
              <div>
                <div className="text-[#605E5C]">Payment Terms:</div>
                <div className="font-bold text-[#323130]">{selectedPO.paymentTerms}</div>
              </div>
              <div>
                <div className="text-[#605E5C]">Total Valuation:</div>
                <div className="font-extrabold text-[#107C10]">{formatTSh(selectedPO.totalAmount)}</div>
              </div>
            </div>

            <div className="border border-[#EDEBE9] rounded-xl overflow-hidden max-h-60 overflow-y-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#F8F8F8] text-[#605E5C] font-bold">
                  <tr>
                    <th className="py-2 px-3">Product</th>
                    <th className="py-2 px-3">Qty</th>
                    <th className="py-2 px-3">Cost Price</th>
                    <th className="py-2 px-3 text-right">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F2F1]">
                  {selectedPO.items.map((it, i) => (
                    <tr key={i}>
                      <td className="py-2 px-3 font-semibold">{it.productName}</td>
                      <td className="py-2 px-3">{it.quantity} {it.unit || 'pcs'}</td>
                      <td className="py-2 px-3 font-mono">{formatTSh(it.costPrice)}</td>
                      <td className="py-2 px-3 font-mono font-bold text-right">{formatTSh(it.costPrice * it.quantity)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="flex justify-between items-center pt-2">
              <button
                onClick={() => alert('Printing Official Stock Inward GRN Receipt...')}
                className="px-3 py-1.5 rounded-lg border border-[#C8C6C4] text-xs font-semibold flex items-center gap-1.5 cursor-pointer"
              >
                <Printer className="w-4 h-4" />
                <span>Print GRN</span>
              </button>

              {selectedPO.status === 'sent' && (
                <button
                  onClick={() => {
                    handleExecuteReceivePO(selectedPO);
                    setIsViewGRNModalOpen(false);
                  }}
                  className="px-4 py-2 rounded-lg bg-[#107C10] text-white text-xs font-bold flex items-center gap-1.5 shadow-xs cursor-pointer"
                >
                  <PackagePlus className="w-4 h-4" />
                  <span>Receive & Stock In Now</span>
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ================= MODAL 3: ADD NEW SUPPLIER ================= */}
      {isAddingSupplier && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form onSubmit={handleSaveNewSupplier} className="bg-white rounded-2xl max-w-md w-full border border-[#E1DFDD] shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <h3 className="font-bold text-sm text-[#323130]">Register New Supplier</h3>
              <button type="button" onClick={() => setIsAddingSupplier(false)} className="text-[#605E5C]">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Company / Supplier Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Zenna Pharma Supply"
                  value={newSupplier.name}
                  onChange={e => setNewSupplier({ ...newSupplier, name: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Contact Person</label>
                  <input
                    type="text"
                    value={newSupplier.contactPerson}
                    onChange={e => setNewSupplier({ ...newSupplier, contactPerson: e.target.value })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Phone Number</label>
                  <input
                    type="text"
                    value={newSupplier.phone}
                    onChange={e => setNewSupplier({ ...newSupplier, phone: e.target.value })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block font-semibold text-[#323130] mb-1">Payment Terms</label>
                <select
                  value={newSupplier.paymentTerms}
                  onChange={e => setNewSupplier({ ...newSupplier, paymentTerms: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                >
                  <option value="Net 30 Days">Net 30 Days (Credit)</option>
                  <option value="Net 15 Days">Net 15 Days (Credit)</option>
                  <option value="Cash on Delivery">Cash on Delivery</option>
                  <option value="Prepayment">Prepayment Required</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-[#EDEBE9]">
              <button
                type="button"
                onClick={() => setIsAddingSupplier(false)}
                className="px-4 py-1.5 text-xs font-semibold text-[#605E5C] bg-[#F3F2F1] rounded-lg"
              >
                {t('cancel')}
              </button>
              <button
                type="submit"
                className="px-5 py-1.5 text-xs font-bold text-white bg-[#6264A7] hover:bg-[#555793] rounded-lg"
              >
                Save Supplier
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ================= MODAL 4: RECORD SUPPLIER PAYMENT ================= */}
      {isRecordingPayment && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form onSubmit={handleSavePayment} className="bg-white rounded-2xl max-w-md w-full border border-[#E1DFDD] shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <h3 className="font-bold text-sm text-[#323130]">Record Supplier Settlement Payment</h3>
              <button type="button" onClick={() => setIsRecordingPayment(false)} className="text-[#605E5C]">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Supplier</label>
                <select
                  value={paymentForm.supplierId}
                  onChange={e => setPaymentForm({ ...paymentForm, supplierId: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                >
                  {suppliers.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.name} (Debt: {formatTSh(s.outstandingPayable)})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-semibold text-[#323130] mb-1">Amount to Pay (TSh) *</label>
                <input
                  type="number"
                  required
                  value={paymentForm.amount}
                  onChange={e => setPaymentForm({ ...paymentForm, amount: Number(e.target.value) })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold"
                />
              </div>

              <div>
                <label className="block font-semibold text-[#323130] mb-1">Payment Method</label>
                <select
                  value={paymentForm.paymentMethod}
                  onChange={e => setPaymentForm({ ...paymentForm, paymentMethod: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                >
                  <option value="CRDB Bank Transfer">CRDB Bank Transfer</option>
                  <option value="NMB Bank Transfer">NMB Bank Transfer</option>
                  <option value="M-Pesa Business Lipa">M-Pesa Business Lipa</option>
                  <option value="Cash Settlement">Cash</option>
                </select>
              </div>

              <div>
                <label className="block font-semibold text-[#323130] mb-1">Transaction Ref #</label>
                <input
                  type="text"
                  value={paymentForm.referenceNumber}
                  onChange={e => setPaymentForm({ ...paymentForm, referenceNumber: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-mono"
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-[#EDEBE9]">
              <button
                type="button"
                onClick={() => setIsRecordingPayment(false)}
                className="px-4 py-1.5 text-xs font-semibold text-[#605E5C] bg-[#F3F2F1] rounded-lg"
              >
                {t('cancel')}
              </button>
              <button
                type="submit"
                className="px-5 py-1.5 text-xs font-bold text-white bg-[#107C10] hover:bg-[#0E6A0E] rounded-lg"
              >
                Record Payment
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
