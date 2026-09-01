import React, { useState, useEffect } from 'react';
import { 
  Boxes, 
  Search, 
  Plus, 
  AlertTriangle, 
  CheckCircle2, 
  Sparkles, 
  Download, 
  Filter, 
  Clock, 
  Tag, 
  X,
  PackageCheck,
  ArrowDownLeft,
  ArrowUpRight,
  History,
  FileText,
  DollarSign,
  AlertOctagon,
  Layers,
  RotateCcw,
  Calendar,
  QrCode,
  Printer
} from 'lucide-react';
import { 
  Language, 
  Product, 
  StockMovement, 
  PurchaseOrder, 
  Supplier, 
  CalendarEvent,
  BusinessType,
} from '@/types/v1';
import { formatTSh, getTranslation } from '@/utils/translations';
import { exportInventoryReport } from '@/utils/reportGenerator';
import { productMatchesSearch } from '@/lib/productMetaDisplay';
import { getWorkplace, getProductNamePlaceholder, getDefaultMainCategory, getDefaultUnit } from '@/lib/businessProfiles';
import { getBusinessProfile } from '@/lib/businessEngine';
import { CategoryTaxonomyPicker, type CategorySelection } from '@/components/v1/CategoryTaxonomyPicker';
import { DynamicProductForm, type DynamicProductFormValues } from '@/components/v1/DynamicProductForm';
import { ProductMetaBadges } from '@/components/v1/ProductMetaBadges';
import { ActionBar } from '@/components/v1/ActionBar';
import { QRCodeModal } from '@/components/v1/QRCodeModal';
import confetti from 'canvas-confetti';
import { api } from '@/lib/api';
import { fetchProductsFromApi, mapProduct, mapStockMovement, optionalApiDate, productToApiPayload } from '@/lib/apiSync';

interface InventoryViewProps {
  language: Language;
  products: Product[];
  setProducts: React.Dispatch<React.SetStateAction<Product[]>>;
  stockMovements: StockMovement[];
  setStockMovements: React.Dispatch<React.SetStateAction<StockMovement[]>>;
  purchaseOrders?: PurchaseOrder[];
  setPurchaseOrders?: React.Dispatch<React.SetStateAction<PurchaseOrder[]>>;
  suppliers?: Supplier[];
  setSuppliers?: React.Dispatch<React.SetStateAction<Supplier[]>>;
  events?: CalendarEvent[];
  setEvents?: React.Dispatch<React.SetStateAction<CalendarEvent[]>>;
  onOpenAIChatWithPrompt?: (prompt: string) => void;
  onReceivePO?: (poId: string) => void;
  businessType?: BusinessType;
  onProductsChanged?: () => void | Promise<void>;
  currentUser?: import('@/types/v1').AuthUser | null;
}

export const InventoryView: React.FC<InventoryViewProps> = ({
  language,
  products,
  setProducts,
  stockMovements,
  setStockMovements,
  purchaseOrders = [],
  setPurchaseOrders,
  suppliers = [],
  setSuppliers,
  events = [],
  setEvents,
  onOpenAIChatWithPrompt,
  onReceivePO,
  businessType = 'retail',
  onProductsChanged,
  currentUser,
}) => {
  const t = (key: any) => getTranslation(language, key);
  const isSw = language === 'sw';
  const workplace = getWorkplace(businessType);
  const defaultCategory = workplace.default_categories?.[0] ?? getDefaultMainCategory(businessType, isSw ? 'sw' : 'en');
  const defaultUnit = workplace.default_units?.[0] ?? getDefaultUnit(businessType);
  const productNamePlaceholder = getProductNamePlaceholder(businessType, isSw ? 'sw' : 'en');
  const showBatch = workplace.features?.batch_tracking ?? false;
  const showExpiry = workplace.features?.expiry_alerts ?? false;
  const showBarcode = workplace.features?.barcode_scan ?? false;

  const handleExportInventory = () => {
    const totalValue = products.reduce((s, p) => s + (p.stock * (p.cost || 0)), 0);
    const lowStock = products.filter(p => p.stock <= (p.reorderPoint || 5)).length;
    exportInventoryReport({
      provider: {
        businessName: currentUser?.businessName || 'Duka+ Business',
        ownerName:    currentUser?.name          || 'Owner',
        email:        currentUser?.email         || '',
        phone:        (currentUser as any)?.phone,
        tinNumber:    (currentUser as any)?.tinNumber,
        branch:       (currentUser as any)?.branch,
        businessType: currentUser?.businessType,
      },
      products: products.map(p => ({
        name:     p.name,
        sku:      p.sku,
        category: p.category,
        stock:    `${p.stock} ${p.unit}`,
        cost:     formatTSh(p.cost || 0),
        value:    formatTSh(p.stock * (p.cost || 0)),
      })),
      totalValue:    formatTSh(totalValue),
      lowStockCount: lowStock,
      language:      language as 'en' | 'sw',
    });
  };

  // Sub tabs: 'catalog' | 'stockin' | 'stockout' | 'movements'
  const [activeTab, setActiveTab] = useState<'catalog' | 'stockin' | 'stockout' | 'movements'>('catalog');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'low' | 'critical' | 'expiring'>('all');
  const [selectedProductId, setSelectedProductId] = useState<string | null>(null);

  // Modals & Drawers
  const [isAddingProduct, setIsAddingProduct] = useState(false);
  const [isQuickStockInOpen, setIsQuickStockInOpen] = useState(false);
  const [isStockOutOpen, setIsStockOutOpen] = useState(false);
  const [successToast, setSuccessToast] = useState<string | null>(null);

  // QR Code Modal State
  const [qrModalProduct, setQrModalProduct] = useState<Product | null>(null);
  const [isQRModalOpen, setIsQRModalOpen] = useState(false);

  // Add Product Form State
  const [customCategories, setCustomCategories] = useState<string[]>([]);
  const [categorySel, setCategorySel] = useState<CategorySelection>({
    main: defaultCategory,
    displayPath: defaultCategory,
  });
  const [dynamicFields, setDynamicFields] = useState<DynamicProductFormValues>({ metadata: {} });

  useEffect(() => {
    const cat = getDefaultMainCategory(businessType, isSw ? 'sw' : 'en');
    const unit = getDefaultUnit(businessType);
    setCategorySel({ main: cat, displayPath: cat });
    setNewProduct(prev => ({
      ...prev,
      category: cat,
      unit,
      batchNumber: showBatch ? `BT-${new Date().getFullYear()}-01` : '',
      expiryDate: showExpiry ? '2028-06-30' : '',
    }));
    setDynamicFields({ metadata: {} });
  }, [businessType, isSw, showBatch, showExpiry]);

  const openAddProductModal = () => {
    const cat = getDefaultMainCategory(businessType, isSw ? 'sw' : 'en');
    setCategorySel({ main: cat, displayPath: cat });
    setDynamicFields({ metadata: {} });
    setNewProduct({
      name: '',
      category: cat,
      sku: `SKU-${Date.now().toString().slice(-4)}`,
      price: 5000,
      cost: 3000,
      stock: 50,
      reorderPoint: 15,
      unit: getDefaultUnit(businessType),
      batchNumber: showBatch ? `BT-${new Date().getFullYear()}-01` : '',
      expiryDate: showExpiry ? '2028-06-30' : '',
    });
    setIsAddingProduct(true);
  };

  const [newProduct, setNewProduct] = useState({
    name: '',
    category: defaultCategory,
    sku: `SKU-${Date.now().toString().slice(-4)}`,
    price: 5000,
    cost: 3000,
    stock: 50,
    reorderPoint: 15,
    unit: defaultUnit,
    batchNumber: showBatch ? `BT-${new Date().getFullYear()}-01` : '',
    expiryDate: showExpiry ? '2028-06-30' : '',
  });

  // Manual Stock In State
  const [manualStockInForm, setManualStockInForm] = useState({
    productId: products[0]?.id || '',
    quantity: 20,
    unitCost: products[0]?.cost || 3000,
    batchNumber: `BT-${new Date().getFullYear()}-R1`,
    expiryDate: '2028-12-31',
    supplierName: suppliers[0]?.name || 'Direct Procurement',
    notes: 'Direct shop stock replenishment',
  });

  // Stock Out / Damage Adjustment State
  const [stockOutForm, setStockOutForm] = useState({
    productId: products[0]?.id || '',
    quantity: 2,
    reason: 'out_damage' as 'out_damage' | 'out_expiry' | 'out_adjustment' | 'out_return',
    notes: 'Packaging damaged during shelf restocking',
    operatorName: 'Store Clerk',
  });

  const triggerToast = (msg: string) => {
    setSuccessToast(msg);
    setTimeout(() => setSuccessToast(null), 5000);
  };

  // 1-Click Receive PO shortcut right inside Inventory
  const handleQuickReceivePO = (po: PurchaseOrder) => {
    if (onReceivePO) {
      onReceivePO(po.id);
      return;
    }

    const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 16);
    let itemsUpdated = 0;
    const updated = [...products];
    const newSm: StockMovement[] = [];

    po.items.forEach(item => {
      const idx = updated.findIndex(p => (item.productId && p.id === item.productId) || p.name.toLowerCase() === item.productName.toLowerCase());
      if (idx >= 0) {
        const prev = updated[idx].stock;
        updated[idx] = {
          ...updated[idx],
          stock: prev + item.quantity,
          cost: item.costPrice > 0 ? item.costPrice : updated[idx].cost,
          batchNumber: item.batchNumber || updated[idx].batchNumber,
          expiryDate: item.expiryDate || updated[idx].expiryDate,
        };
        itemsUpdated++;

        newSm.push({
          id: `sm-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
          date: nowStr,
          productId: updated[idx].id,
          productName: updated[idx].name,
          sku: updated[idx].sku,
          type: 'in_purchase',
          quantity: item.quantity,
          previousStock: prev,
          newStock: prev + item.quantity,
          unitCost: item.costPrice,
          totalValuation: item.quantity * item.costPrice,
          referenceId: po.poNumber,
          referenceType: 'PO',
          operatorName: 'Store Manager',
          notes: `Quick Stock In from ${po.supplierName}`,
        });
      } else {
        const newId = `prod-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`;
        const newProd: Product = {
          id: newId,
          name: item.productName,
          category: item.category || 'General',
          sku: item.sku || `SKU-${Math.floor(1000 + Math.random() * 9000)}`,
          price: item.sellingPrice || Math.round(item.costPrice * 1.4),
          cost: item.costPrice,
          stock: item.quantity,
          reorderPoint: 10,
          unit: item.unit || 'boxes',
          batchNumber: item.batchNumber || `BT-${new Date().getFullYear()}`,
          expiryDate: item.expiryDate || '2028-12-31',
          businessType: businessType,
        };
        updated.unshift(newProd);
        itemsUpdated++;

        newSm.push({
          id: `sm-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
          date: nowStr,
          productId: newId,
          productName: newProd.name,
          sku: newProd.sku,
          type: 'in_purchase',
          quantity: item.quantity,
          previousStock: 0,
          newStock: item.quantity,
          unitCost: item.costPrice,
          totalValuation: item.quantity * item.costPrice,
          referenceId: po.poNumber,
          referenceType: 'PO',
          operatorName: 'Store Manager',
          notes: `New Item Registered from ${po.supplierName}`,
        });
      }
    });

    setProducts(updated);
    setStockMovements(prev => [...newSm, ...prev]);

    if (setPurchaseOrders) {
      setPurchaseOrders(prev => prev.map(p => p.id === po.id ? { ...p, status: 'received', receivedDate: nowStr } : p));
    }

    confetti({ particleCount: 50, spread: 60, origin: { y: 0.7 } });
    triggerToast(`Order ${po.poNumber} received & ${itemsUpdated} items stocked into inventory!`);
  };

  // Action: Add New Product
  const handleSaveProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newProduct.name) return;

    try {
      await api.createProduct({
        ...productToApiPayload({
          name: newProduct.name,
          category: categorySel.displayPath || newProduct.category,
          sku: newProduct.sku,
          price: Number(newProduct.price),
          cost: Number(newProduct.cost),
          stock: Number(newProduct.stock),
          reorderPoint: Number(newProduct.reorderPoint),
          unit: newProduct.unit,
          batchNumber: dynamicFields.batch_number ?? newProduct.batchNumber,
          expiryDate: dynamicFields.expiry_date ?? newProduct.expiryDate,
          requiresPrescription: Boolean(dynamicFields.requires_prescription),
          businessType,
        }),
        metadata_json: dynamicFields.metadata,
        business_type: businessType,
      });
      const refreshed = await fetchProductsFromApi();
      setProducts(refreshed);
      await onProductsChanged?.();
      setIsAddingProduct(false);
      confetti({ particleCount: 40, spread: 50, origin: { y: 0.8 } });
      triggerToast(`Product ${newProduct.name} registered with ${newProduct.stock} units!`);
    } catch (err) {
      alert((err as Error).message);
    }
  };

  // Action: Manual Stock In
  const handleExecuteManualStockIn = async (e: React.FormEvent) => {
    e.preventDefault();
    const prod = products.find(p => p.id === manualStockInForm.productId);
    if (!prod) return;

    const qty = Number(manualStockInForm.quantity);
    const unitCost = Number(manualStockInForm.unitCost);

    try {
      const movRaw = await api.adjustStock({
        product_id: prod.id,
        quantity: qty,
        movement_type: 'in_adjustment',
        batch_number: manualStockInForm.batchNumber,
        expiry_date: optionalApiDate(manualStockInForm.expiryDate),
        notes: `Manual Stock In: ${manualStockInForm.notes} (${manualStockInForm.supplierName})`,
      });
      const updatedRaw = await api.updateProduct(prod.id, {
        cost: unitCost > 0 ? unitCost : prod.cost,
        batch_number: manualStockInForm.batchNumber || prod.batchNumber,
        expiry_date: optionalApiDate(manualStockInForm.expiryDate || prod.expiryDate),
      });
      setProducts(prev => prev.map(p => p.id === prod.id ? mapProduct(updatedRaw as Record<string, unknown>) : p));
      setStockMovements(prev => [mapStockMovement(movRaw as Record<string, unknown>), ...prev]);
      setIsQuickStockInOpen(false);
      triggerToast(`Stocked In +${qty} ${prod.unit} of ${prod.name}!`);
    } catch (err) {
      alert((err as Error).message);
    }
  };

  // Action: Manual Stock Out / Write-off
  const handleExecuteStockOut = async (e: React.FormEvent) => {
    e.preventDefault();
    const prod = products.find(p => p.id === stockOutForm.productId);
    if (!prod) return;

    const qty = Number(stockOutForm.quantity);

    try {
      const movRaw = await api.adjustStock({
        product_id: prod.id,
        quantity: -qty,
        movement_type: stockOutForm.reason === 'expired' ? 'out_expired' : 'out_adjustment',
        notes: stockOutForm.notes,
      });
      const updatedRaw = await api.getProducts();
      setProducts((updatedRaw as Array<Record<string, unknown>>).map(mapProduct));
      await onProductsChanged?.();
      setStockMovements(prev => [mapStockMovement(movRaw as Record<string, unknown>), ...prev]);
      setIsStockOutOpen(false);
      triggerToast(`Stock Out -${qty} ${prod.unit} of ${prod.name}`);
    } catch (err) {
      alert((err as Error).message);
    }
  };

  // Filter products
  const filteredProducts = products.filter(p => {
    const matchesSearch = productMatchesSearch(p, businessType, searchQuery)
      || p.sku.toLowerCase().includes(searchQuery.toLowerCase())
      || p.category.toLowerCase().includes(searchQuery.toLowerCase());

    if (filterType === 'low') return matchesSearch && p.stock <= p.reorderPoint;
    if (filterType === 'critical') return matchesSearch && p.stock <= 5;
    if (filterType === 'expiring') return matchesSearch && (p.expiryDate && p.expiryDate.startsWith('2027'));
    return matchesSearch;
  });

  // Financial Valuation Metrics
  const totalCostValuation = products.reduce((sum, p) => sum + (p.stock * p.cost), 0);
  const totalRetailValuation = products.reduce((sum, p) => sum + (p.stock * p.price), 0);
  const potentialGrossProfit = totalRetailValuation - totalCostValuation;
  const potentialMarginPercent = totalRetailValuation > 0 ? Math.round((potentialGrossProfit / totalRetailValuation) * 100) : 0;
  const lowStockCount = products.filter(p => p.stock <= p.reorderPoint).length;
  const criticalStockCount = products.filter(p => p.stock <= 5).length;
  const pendingOrders = purchaseOrders.filter(po => po.status === 'sent');

  return (
    <div className="space-y-6 pb-16">
      {/* Toast Alert */}
      {successToast && (
        <div className="p-4 bg-emerald-50 border border-emerald-300 rounded-xl text-emerald-900 shadow-sm flex items-center gap-3 animate-in fade-in duration-200">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span className="text-xs font-bold">{successToast}</span>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-[#323130] tracking-tight">
              {workplace.icon} {isSw ? workplace.inventory_title_sw : workplace.inventory_title_en}
            </h2>
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#107C10]/10 text-[#107C10] border border-[#107C10]/20">
              Live Real-Time Sync
            </span>
          </div>
          <p className="text-xs text-[#605E5C] mt-0.5">
            {isSw
              ? `${workplace.label_sw} · Udhibiti wa stoo · Thamani ya mali`
              : `${workplace.label_en} · Stock control · Asset valuation`}
            {showBatch && (isSw ? ' · Ufuatiliaji wa batch' : ' · Batch tracking')}
            {showExpiry && (isSw ? ' · Tarehe ya kuisha' : ' · Expiry alerts')}
            {workplace.features.fractional_units && (isSw ? ' · Vipimo vya sehemu' : ' · Fractional units')}
            {workplace.features.table_management && (isSw ? ' · Meza/KOT' : ' · Table/KOT')}
            {workplace.features.appointments && (isSw ? ' · Miadi' : ' · Appointments')}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsQuickStockInOpen(true)}
            className="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-[#107C10] hover:bg-[#0E6A0E] text-white font-bold text-xs shadow-xs transition-all cursor-pointer"
          >
            <ArrowDownLeft className="w-4 h-4" />
            <span>{t('stockIn')}</span>
          </button>

          <button
            onClick={() => setIsStockOutOpen(true)}
            className="flex items-center gap-1.5 px-3 py-2 rounded-lg bg-white hover:bg-rose-50 text-[#D13438] font-bold text-xs border border-rose-200 shadow-xs transition-all cursor-pointer"
          >
            <ArrowUpRight className="w-4 h-4 text-[#D13438]" />
            <span>{t('stockOut')}</span>
          </button>

          <button
            id="btn-add-product-top"
            onClick={openAddProductModal}
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-[#6264A7] hover:bg-[#555793] text-white font-bold text-xs shadow-xs transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Add Product</span>
          </button>
        </div>
      </div>

      {/* Financial Valuation KPI Matrix */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Total Stock Asset Value (Cost)</div>
          <div className="text-xl font-extrabold text-[#323130] mt-1 font-mono">{formatTSh(totalCostValuation)}</div>
          <div className="text-[11px] text-[#605E5C] mt-1">{products.length} Active SKUs in Catalog</div>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Total Retail Potential Value</div>
          <div className="text-xl font-extrabold text-[#0078D4] mt-1 font-mono">{formatTSh(totalRetailValuation)}</div>
          <div className="text-[11px] text-[#107C10] font-semibold mt-1">Est. Gross Margin: ~{potentialMarginPercent}%</div>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Reorder Triggers</div>
          <div className="text-xl font-extrabold text-amber-600 mt-1">{lowStockCount} Low Items</div>
          <div className="text-[11px] text-[#D13438] font-semibold mt-1">{criticalStockCount} Critical (&le; 5 units)</div>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="text-xs font-medium text-[#605E5C]">Pending Deliveries from POs</div>
          <div className="text-xl font-extrabold text-[#6264A7] mt-1">{pendingOrders.length} Inbound POs</div>
          <div className="text-[11px] text-[#605E5C] mt-1">Ready for 1-Click Stock-In</div>
        </div>
      </div>

      {/* Sub-Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#EDEBE9] pb-2">
        <button
          onClick={() => setActiveTab('catalog')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'catalog'
              ? 'bg-[#6264A7] text-white shadow-xs'
              : 'bg-white text-[#605E5C] hover:bg-[#F3F2F1] border border-[#E1DFDD]'
          }`}
        >
          <Boxes className="w-4 h-4" />
          <span>Product Catalog ({products.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('stockin')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'stockin'
              ? 'bg-[#107C10] text-white shadow-xs'
              : 'bg-white text-[#605E5C] hover:bg-[#F3F2F1] border border-[#E1DFDD]'
          }`}
        >
          <ArrowDownLeft className="w-4 h-4" />
          <span>Inbound Goods & PO Receive ({pendingOrders.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('movements')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
            activeTab === 'movements'
              ? 'bg-[#6264A7] text-white shadow-xs'
              : 'bg-white text-[#605E5C] hover:bg-[#F3F2F1] border border-[#E1DFDD]'
          }`}
        >
          <History className="w-4 h-4" />
          <span>Stock Movement Audit Trail ({stockMovements.length})</span>
        </button>
      </div>

      {/* ACTION BAR */}
      <ActionBar
        language={language}
        onAdd={openAddProductModal}
        onAISuggest={() => {
          if (onOpenAIChatWithPrompt) {
            onOpenAIChatWithPrompt('Toa ripoti kamili ya uchambuzi wa bidhaa za stoo, utabiri wa mahitaji (Inventory Forecasting), na orodha ya bidhaa za kuagiza kwa wasambazaji.');
          }
        }}
        onExport={handleExportInventory}
        customAddLabel="➕ Add Product"
        selectedCount={selectedProductId ? 1 : 0}
        totalCount={products.length}
      />

      {/* ================= TAB 1: PRODUCT CATALOG ================= */}
      {activeTab === 'catalog' && (
        <div className="space-y-4">
          {/* SEARCH & FILTERS */}
          <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs flex flex-wrap items-center justify-between gap-4">
            <div className="relative flex-1 min-w-[260px] max-w-md">
              <Search className="w-4 h-4 text-[#605E5C] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search product name, category, or SKU..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-1.5 text-xs bg-[#F3F2F1] border border-transparent focus:border-[#0078D4] focus:bg-white rounded-lg outline-none"
              />
            </div>

            <div className="flex items-center gap-1.5 text-xs font-semibold">
              <button
                onClick={() => {
                  setQrModalProduct(products[0] || null);
                  setIsQRModalOpen(true);
                }}
                className="px-3 py-1.5 rounded-lg bg-[#6264A7] hover:bg-[#555793] text-white shadow-xs flex items-center gap-1.5 transition-all cursor-pointer"
                title="Generate & Print QR Code Shelf Labels"
              >
                <QrCode className="w-3.5 h-3.5" />
                <span>QR Shelf Labels</span>
              </button>
              <button
                onClick={() => setFilterType('all')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  filterType === 'all' ? 'bg-[#323130] text-white shadow-xs' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                All Stock ({products.length})
              </button>
              <button
                onClick={() => setFilterType('low')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  filterType === 'low' ? 'bg-[#D13438] text-white shadow-xs' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                ⚠️ Low Stock ({lowStockCount})
              </button>
              <button
                onClick={() => setFilterType('critical')}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  filterType === 'critical' ? 'bg-rose-900 text-white shadow-xs' : 'bg-[#F3F2F1] text-[#605E5C]'
                }`}
              >
                🚨 Critical ({criticalStockCount})
              </button>
            </div>
          </div>

          {/* PRODUCTS DATA TABLE */}
          <div className="bg-white rounded-xl border border-[#E1DFDD] shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#F8F8F8] border-b border-[#EDEBE9] text-[#605E5C] font-bold uppercase tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Product Name & Category</th>
                    <th className="py-3 px-3">{showBatch ? 'SKU & Batch' : 'SKU'}</th>
                    <th className="py-3 px-3">Selling Price</th>
                    <th className="py-3 px-3">Cost Price</th>
                    <th className="py-3 px-3">Stock Level</th>
                    <th className="py-3 px-3">Asset Value</th>
                    {showExpiry && <th className="py-3 px-3">Expiry Date</th>}
                    <th className="py-3 px-4 text-right">Quick Stock</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F2F1]">
                  {filteredProducts.map(prod => {
                    const isLow = prod.stock <= prod.reorderPoint;
                    const isCritical = prod.stock <= 5;
                    const isSelected = selectedProductId === prod.id;

                    return (
                      <tr 
                        key={prod.id}
                        onClick={() => setSelectedProductId(prod.id)}
                        className={`hover:bg-[#FAF9F8] transition-colors cursor-pointer ${
                          isSelected ? 'bg-[#F0F2FA]' : ''
                        }`}
                      >
                        <td className="py-3 px-4">
                          <div className="font-bold text-[#323130]">{prod.name}</div>
                          <div className="text-[10px] text-[#605E5C]">{prod.category}</div>
                          <ProductMetaBadges
                            product={prod}
                            businessType={businessType}
                            language={language}
                            max={3}
                            className="mt-1"
                          />
                        </td>

                        <td className="py-3 px-3 font-mono">
                          <div className="text-[11px] text-[#323130] font-bold">{prod.sku}</div>
                          {showBatch && (
                            <div className="text-[10px] text-[#605E5C]">{prod.batchNumber || 'N/A'}</div>
                          )}
                        </td>

                        <td className="py-3 px-3 font-bold text-[#0078D4] font-mono">
                          {formatTSh(prod.price)}
                        </td>

                        <td className="py-3 px-3 text-[#605E5C] font-mono">
                          {formatTSh(prod.cost)}
                        </td>

                        <td className="py-3 px-3">
                          <div className="flex items-center gap-1.5">
                            <span className={`font-extrabold ${isCritical ? 'text-[#D13438]' : isLow ? 'text-amber-600' : 'text-[#107C10]'}`}>
                              {prod.stock} {prod.unit}
                            </span>
                            {isLow && (
                              <span className={`text-[9px] font-bold px-1.5 py-0.2 rounded-full ${
                                isCritical ? 'bg-rose-100 text-rose-800' : 'bg-amber-100 text-amber-800'
                              }`}>
                                {isCritical ? 'Critical' : 'Low'}
                              </span>
                            )}
                          </div>
                          <div className="text-[9px] text-[#605E5C]">Min: {prod.reorderPoint}</div>
                        </td>

                        <td className="py-3 px-3 font-mono font-semibold text-[#323130]">
                          {formatTSh(prod.stock * prod.cost)}
                        </td>

                        {showExpiry && (
                          <td className="py-3 px-3 text-[#605E5C] font-mono">
                            {prod.expiryDate || '—'}
                          </td>
                        )}

                        <td className="py-3 px-4 text-right">
                          <div className="flex items-center justify-end gap-1.5" onClick={e => e.stopPropagation()}>
                            <button
                              onClick={() => {
                                setQrModalProduct(prod);
                                setIsQRModalOpen(true);
                              }}
                              className="p-1.5 bg-indigo-50 hover:bg-indigo-100 text-[#6264A7] rounded-lg border border-indigo-200 font-bold text-[11px] cursor-pointer transition-all"
                              title="Generate QR Code & Print Shelf Label"
                            >
                              <QrCode className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => {
                                setStockOutForm(prev => ({ ...prev, productId: prod.id, quantity: 1 }));
                                setIsStockOutOpen(true);
                              }}
                              className="px-2 py-1 bg-[#F3F2F1] hover:bg-rose-100 text-rose-800 rounded-lg font-bold text-[11px] cursor-pointer"
                              title="Stock Out / Damage / Loss"
                            >
                              - Out
                            </button>
                            <button
                              onClick={() => {
                                setManualStockInForm(prev => ({ ...prev, productId: prod.id, unitCost: prod.cost }));
                                setIsQuickStockInOpen(true);
                              }}
                              className="px-2.5 py-1 bg-[#107C10] hover:bg-[#0E6A0E] text-white rounded-lg font-bold text-[11px] shadow-xs cursor-pointer"
                              title="Stock In / Restock"
                            >
                              + In
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ================= TAB 2: INBOUND GOODS & 1-CLICK PO RECEIVE ================= */}
      {activeTab === 'stockin' && (
        <div className="space-y-4">
          <div className="flex justify-between items-center bg-white p-4 rounded-xl border border-[#E1DFDD] shadow-xs">
            <div>
              <h3 className="font-bold text-sm text-[#323130]">Inbound Goods & 1-Click Purchase Order Fulfillment</h3>
              <p className="text-xs text-[#605E5C]">Instantly update inventory levels and register new products from supplier deliveries</p>
            </div>
            <button
              onClick={() => setIsQuickStockInOpen(true)}
              className="px-4 py-2 rounded-lg bg-[#107C10] text-white font-bold text-xs flex items-center gap-1.5 cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Direct Manual Stock In</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {pendingOrders.length === 0 ? (
              <div className="col-span-2 text-center py-12 bg-white rounded-xl border border-[#EDEBE9] text-xs text-[#605E5C] space-y-2">
                <CheckCircle2 className="w-8 h-8 text-[#107C10] mx-auto" />
                <div className="font-bold text-sm text-[#323130]">All Supplier Deliveries Received</div>
                <p>There are no pending purchase orders awaiting stock-in at this time.</p>
              </div>
            ) : (
              pendingOrders.map(po => (
                <div key={po.id} className="bg-white rounded-xl border-2 border-amber-300 p-5 shadow-xs space-y-3">
                  <div className="flex justify-between items-start">
                    <div>
                      <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded bg-amber-100 text-amber-800">
                        Inbound Shipment Pending
                      </span>
                      <h4 className="font-bold text-base text-[#323130] mt-1">{po.poNumber} — {po.supplierName}</h4>
                      <p className="text-xs text-[#605E5C]">Expected Date: {po.expectedDate} • Terms: {po.paymentTerms}</p>
                    </div>
                    <div className="text-right">
                      <div className="text-xs text-[#605E5C]">Valuation</div>
                      <div className="text-base font-extrabold text-[#323130] font-mono">{formatTSh(po.totalAmount)}</div>
                    </div>
                  </div>

                  <div className="bg-[#FAF9F8] rounded-lg p-3 border border-[#EDEBE9] space-y-1 text-xs">
                    <div className="font-bold text-[#605E5C] text-[10px] uppercase">Manifest Items:</div>
                    {po.items.map((it, idx) => (
                      <div key={idx} className="flex justify-between text-[#323130]">
                        <span className="flex items-center gap-1.5">
                          • {it.productName} 
                          {it.isNewProduct && <span className="text-[9px] font-bold px-1 bg-blue-100 text-blue-800 rounded">NEW</span>}
                        </span>
                        <span className="font-bold font-mono">{it.quantity} {it.unit || 'pcs'} @ {formatTSh(it.costPrice)}</span>
                      </div>
                    ))}
                  </div>

                  <button
                    onClick={() => handleQuickReceivePO(po)}
                    className="w-full py-2.5 rounded-xl bg-[#107C10] hover:bg-[#0E6A0E] text-white font-bold text-xs flex items-center justify-center gap-2 shadow-xs transition-all cursor-pointer"
                  >
                    <PackageCheck className="w-4 h-4" />
                    <span>1-Click Receive & Stock Into Inventory</span>
                  </button>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {/* ================= TAB 3: STOCK MOVEMENT AUDIT TRAIL ================= */}
      {activeTab === 'movements' && (
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-[#E1DFDD] shadow-xs overflow-hidden">
            <div className="p-4 border-b border-[#EDEBE9] flex justify-between items-center">
              <div>
                <h3 className="font-bold text-sm text-[#323130]">Stock Movement & Audit Log</h3>
                <p className="text-xs text-[#605E5C]">Complete immutable ledger of sales, receipts, damages, and manual adjustments</p>
              </div>
              <span className="text-xs font-mono text-[#605E5C]">{stockMovements.length} logged events</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#F8F8F8] border-b border-[#EDEBE9] text-[#605E5C] font-bold uppercase">
                  <tr>
                    <th className="py-3 px-4">Date & Time</th>
                    <th className="py-3 px-3">Product Name & SKU</th>
                    <th className="py-3 px-3">Movement Type</th>
                    <th className="py-3 px-3">Quantity Delta</th>
                    <th className="py-3 px-3">Stock Before / After</th>
                    <th className="py-3 px-3">Valuation Impact</th>
                    <th className="py-3 px-3">Reference / Txn</th>
                    <th className="py-3 px-4">Staff / Notes</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F2F1]">
                  {stockMovements.map(sm => {
                    const isIn = sm.quantity > 0;
                    return (
                      <tr key={sm.id} className="hover:bg-[#FAF9F8]">
                        <td className="py-3 px-4 font-mono text-[#605E5C]">{sm.date}</td>

                        <td className="py-3 px-3">
                          <div className="font-bold text-[#323130]">{sm.productName}</div>
                          <div className="text-[10px] text-[#605E5C] font-mono">{sm.sku}</div>
                        </td>

                        <td className="py-3 px-3">
                          <span className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            sm.type === 'in_purchase' 
                              ? 'bg-emerald-100 text-emerald-800'
                              : sm.type === 'out_sale'
                              ? 'bg-blue-100 text-blue-800'
                              : sm.type === 'out_damage' || sm.type === 'out_expiry'
                              ? 'bg-rose-100 text-rose-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}>
                            {isIn ? <ArrowDownLeft className="w-3 h-3" /> : <ArrowUpRight className="w-3 h-3" />}
                            {sm.type.replace('_', ' ').toUpperCase()}
                          </span>
                        </td>

                        <td className="py-3 px-3 font-extrabold font-mono">
                          <span className={isIn ? 'text-[#107C10]' : 'text-[#D13438]'}>
                            {isIn ? `+${sm.quantity}` : sm.quantity}
                          </span>
                        </td>

                        <td className="py-3 px-3 font-mono text-[#605E5C]">
                          {sm.previousStock} &rarr; <span className="font-bold text-[#323130]">{sm.newStock}</span>
                        </td>

                        <td className="py-3 px-3 font-mono text-[#323130]">
                          {formatTSh(sm.totalValuation || 0)}
                        </td>

                        <td className="py-3 px-3 font-mono text-[#0078D4] font-semibold">
                          {sm.referenceId || sm.referenceType || 'MANUAL'}
                        </td>

                        <td className="py-3 px-4">
                          <div className="text-[11px] font-semibold text-[#323130]">{sm.operatorName}</div>
                          <div className="text-[10px] text-[#605E5C]">{sm.notes || '-'}</div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ================= MODAL 1: ADD NEW PRODUCT ================= */}
      {isAddingProduct && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleSaveProduct}
            className="bg-white rounded-2xl max-w-2xl w-full border border-[#E1DFDD] shadow-2xl flex flex-col max-h-[min(92vh,880px)] overflow-hidden"
          >
            <div className="flex items-center justify-between border-b border-[#EDEBE9] px-6 py-4 shrink-0">
              <div className="flex items-center gap-2">
                <Boxes className="w-5 h-5 text-[#6264A7]" />
                <h3 className="font-bold text-sm text-[#323130]">
                  {isSw ? 'Sajili Bidhaa Mpya' : 'Register New Product to Catalog'}
                </h3>
              </div>
              <button type="button" onClick={() => setIsAddingProduct(false)} className="text-[#605E5C] cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="overflow-y-auto flex-1 min-h-0 px-6 py-4 space-y-4 text-xs">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="md:col-span-2">
                <label className="block font-semibold text-[#323130] mb-1">
                  {isSw ? 'Jina la Bidhaa *' : 'Product Name *'}
                </label>
                <input
                  type="text"
                  required
                  placeholder={productNamePlaceholder}
                  value={newProduct.name}
                  onChange={e => setNewProduct({ ...newProduct, name: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
              <div>
                <CategoryTaxonomyPicker
                  language={language}
                  businessType={businessType}
                  value={categorySel}
                  onChange={(sel) => {
                    setCategorySel(sel);
                    setNewProduct({ ...newProduct, category: sel.displayPath });
                  }}
                  customCategories={customCategories}
                  onAddCustom={(path) => setCustomCategories(prev => [...prev, path])}
                />
              </div>
              <div>
                <label className="block font-semibold text-[#323130] mb-1">{isSw ? 'Kipimo' : 'Unit'}</label>
                <select
                  value={newProduct.unit}
                  onChange={e => setNewProduct({ ...newProduct, unit: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                >
                  {workplace.default_units.map(u => <option key={u} value={u}>{u}</option>)}
                </select>
              </div>
            </div>

            <DynamicProductForm
              language={language}
              businessType={businessType}
              values={dynamicFields}
              onChange={setDynamicFields}
            />

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Selling Price (TSh)</label>
                <input
                  type="number"
                  value={newProduct.price}
                  onChange={e => setNewProduct({ ...newProduct, price: Number(e.target.value) })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold"
                />
              </div>
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Cost Price (TSh)</label>
                <input
                  type="number"
                  value={newProduct.cost}
                  onChange={e => setNewProduct({ ...newProduct, cost: Number(e.target.value) })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold"
                />
              </div>
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Opening Stock Qty</label>
                <input
                  type="number"
                  value={newProduct.stock}
                  onChange={e => setNewProduct({ ...newProduct, stock: Number(e.target.value) })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold"
                />
              </div>
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Reorder Point</label>
                <input
                  type="number"
                  value={newProduct.reorderPoint}
                  onChange={e => setNewProduct({ ...newProduct, reorderPoint: Number(e.target.value) })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block font-semibold text-[#323130] mb-1">SKU / Code</label>
                <input
                  type="text"
                  value={newProduct.sku}
                  onChange={e => setNewProduct({ ...newProduct, sku: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
              {showBatch && (
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Batch / Lot #</label>
                <input
                  type="text"
                  value={newProduct.batchNumber}
                  onChange={e => setNewProduct({ ...newProduct, batchNumber: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
              )}
              {showExpiry && (
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Expiry Date</label>
                <input
                  type="date"
                  value={newProduct.expiryDate}
                  onChange={e => setNewProduct({ ...newProduct, expiryDate: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
              )}
            </div>
            </div>

            <div className="flex justify-end gap-2 px-6 py-4 border-t border-[#EDEBE9] bg-[#FAF9F8] rounded-b-2xl shrink-0">
              <button
                type="button"
                onClick={() => setIsAddingProduct(false)}
                className="px-4 py-1.5 text-xs font-semibold text-[#605E5C] bg-[#F3F2F1] rounded-lg"
              >
                {t('cancel')}
              </button>
              <button
                type="submit"
                className="px-5 py-1.5 text-xs font-bold text-white bg-[#6264A7] hover:bg-[#555793] rounded-lg"
              >
                Save & Open Stock
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ================= MODAL 2: DIRECT MANUAL STOCK IN ================= */}
      {isQuickStockInOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form onSubmit={handleExecuteManualStockIn} className="bg-white rounded-2xl max-w-md w-full border border-[#E1DFDD] shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <div className="flex items-center gap-2">
                <ArrowDownLeft className="w-5 h-5 text-[#107C10]" />
                <h3 className="font-bold text-sm text-[#323130]">Manual Stock In Replenishment</h3>
              </div>
              <button type="button" onClick={() => setIsQuickStockInOpen(false)} className="text-[#605E5C]">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Select Product *</label>
                <select
                  value={manualStockInForm.productId}
                  onChange={e => {
                    const sel = products.find(p => p.id === e.target.value);
                    setManualStockInForm({
                      ...manualStockInForm,
                      productId: e.target.value,
                      unitCost: sel?.cost || 3000,
                    });
                  }}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                >
                  {products.map(p => (
                    <option key={p.id} value={p.id}>{p.name} (Current: {p.stock} {p.unit})</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Quantity to Inward</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={manualStockInForm.quantity}
                    onChange={e => setManualStockInForm({ ...manualStockInForm, quantity: Number(e.target.value) })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Unit Cost (TSh)</label>
                  <input
                    type="number"
                    value={manualStockInForm.unitCost}
                    onChange={e => setManualStockInForm({ ...manualStockInForm, unitCost: Number(e.target.value) })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Batch #</label>
                  <input
                    type="text"
                    value={manualStockInForm.batchNumber}
                    onChange={e => setManualStockInForm({ ...manualStockInForm, batchNumber: e.target.value })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Expiry Date</label>
                  <input
                    type="date"
                    value={manualStockInForm.expiryDate}
                    onChange={e => setManualStockInForm({ ...manualStockInForm, expiryDate: e.target.value })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block font-semibold text-[#323130] mb-1">Supplier Source / Notes</label>
                <input
                  type="text"
                  placeholder="e.g. Direct manufacturer delivery"
                  value={manualStockInForm.notes}
                  onChange={e => setManualStockInForm({ ...manualStockInForm, notes: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-[#EDEBE9]">
              <button
                type="button"
                onClick={() => setIsQuickStockInOpen(false)}
                className="px-4 py-1.5 text-xs font-semibold text-[#605E5C] bg-[#F3F2F1] rounded-lg"
              >
                {t('cancel')}
              </button>
              <button
                type="submit"
                className="px-5 py-1.5 text-xs font-bold text-white bg-[#107C10] hover:bg-[#0E6A0E] rounded-lg shadow-xs"
              >
                Execute Stock In
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ================= MODAL 3: STOCK OUT / DAMAGE ADJUSTMENT ================= */}
      {isStockOutOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
          <form onSubmit={handleExecuteStockOut} className="bg-white rounded-2xl max-w-md w-full border border-[#E1DFDD] shadow-2xl p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <div className="flex items-center gap-2">
                <ArrowUpRight className="w-5 h-5 text-[#D13438]" />
                <h3 className="font-bold text-sm text-[#323130]">Stock Out & Damage Deduction</h3>
              </div>
              <button type="button" onClick={() => setIsStockOutOpen(false)} className="text-[#605E5C]">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-[#323130] mb-1">Product *</label>
                <select
                  value={stockOutForm.productId}
                  onChange={e => setStockOutForm({ ...stockOutForm, productId: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                >
                  {products.map(p => (
                    <option key={p.id} value={p.id}>{p.name} (Current Stock: {p.stock})</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Quantity to Deduct</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={stockOutForm.quantity}
                    onChange={e => setStockOutForm({ ...stockOutForm, quantity: Number(e.target.value) })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none font-bold text-[#D13438]"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-[#323130] mb-1">Reason for Deduction</label>
                  <select
                    value={stockOutForm.reason}
                    onChange={e => setStockOutForm({ ...stockOutForm, reason: e.target.value as any })}
                    className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                  >
                    <option value="out_damage">Damaged Packaging / Broken</option>
                    <option value="out_expiry">Expired Stock Write-off</option>
                    <option value="out_adjustment">Inventory Audit Discrepancy</option>
                    <option value="out_return">Return to Supplier</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block font-semibold text-[#323130] mb-1">Detailed Notes</label>
                <input
                  type="text"
                  placeholder="e.g. Broken vial during morning shelf cleaning"
                  value={stockOutForm.notes}
                  onChange={e => setStockOutForm({ ...stockOutForm, notes: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg border border-[#EDEBE9] focus:bg-white outline-none"
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-[#EDEBE9]">
              <button
                type="button"
                onClick={() => setIsStockOutOpen(false)}
                className="px-4 py-1.5 text-xs font-semibold text-[#605E5C] bg-[#F3F2F1] rounded-lg"
              >
                {t('cancel')}
              </button>
              <button
                type="submit"
                className="px-5 py-1.5 text-xs font-bold text-white bg-[#D13438] hover:bg-[#B12A2E] rounded-lg shadow-xs"
              >
                Deduct & Write-Off Stock
              </button>
            </div>
          </form>
        </div>
      )}

      {/* QR Code & Shelf Label Modal */}
      <QRCodeModal
        isOpen={isQRModalOpen}
        onClose={() => setIsQRModalOpen(false)}
        product={qrModalProduct}
        allProducts={products}
        language={language}
      />
    </div>
  );
};
