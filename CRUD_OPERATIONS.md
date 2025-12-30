# CRUD OPERATIONS - Invoice Generator App

## Overview
This document details all CRUD (Create, Read, Update, Delete) operations implemented in the Invoice Generator application.

---

## 📋 INVOICE CRUD OPERATIONS

### ✅ CREATE - Add New Invoice
**Screen**: Create Invoice Screen  
**File**: `lib/screens/create_invoice_screen.dart`

**Process:**
1. User selects client from dropdown
2. Adds line items (product, quantity, price)
3. System auto-calculates subtotal, tax, and total
4. User sets issue date, due date, payment terms
5. Adds optional notes
6. Clicks "Save Invoice" button

**Code Implementation:**
```dart
// InvoiceProvider
Future<void> createAndSaveInvoice(Invoice invoice) async {
  final docRef = await firebaseService.addInvoice(invoice);
  invoices.add(invoice.copyWith(id: docRef.id));
  notifyListeners();
}

// FirebaseService
Future<DocumentReference> addInvoice(Invoice invoice) async {
  return await FirebaseFirestore.instance
      .collection('invoices')
      .add(invoice.toFirestore());
}
```

**Validation:**
- Client must be selected
- At least one line item required
- Valid dates (issue date ≤ due date)
- Positive amounts

---

### 📖 READ - View Invoices
**Screens**: 
- Invoices List Screen
- Invoice Details Screen

**File**: `lib/screens/invoices_list_screen.dart`

**Process:**
1. Fetch all invoices from Firestore
2. Display in list with client name, amount, status
3. Support search by invoice number or client name
4. Filter by date range or status
5. Click invoice to view full details

**Code Implementation:**
```dart
// InvoiceProvider
Future<void> loadInvoices() async {
  invoices = await firebaseService.fetchInvoices(userId);
  notifyListeners();
}

// FirebaseService
Future<List<Invoice>> fetchInvoices(String userId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('invoices')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();
  
  return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
}
```

**Features:**
- Real-time search
- Date range filtering
- Status filtering (draft, sent, paid)
- Sort by date, amount, client

---

### ✏️ UPDATE - Edit Invoice
**Screen**: Edit Invoice Screen  
**File**: `lib/screens/create_invoice_screen.dart` (edit mode)

**Process:**
1. User clicks "Edit" on existing invoice
2. Pre-fill form with current invoice data
3. User modifies client, items, dates, or notes
4. System recalculates totals on changes
5. Clicks "Update Invoice" button

**Code Implementation:**
```dart
// InvoiceProvider
Future<void> updateInvoice(String invoiceId, Invoice updatedInvoice) async {
  await firebaseService.updateInvoice(invoiceId, updatedInvoice);
  final index = invoices.indexWhere((inv) => inv.id == invoiceId);
  if (index != -1) {
    invoices[index] = updatedInvoice;
    notifyListeners();
  }
}

// FirebaseService
Future<void> updateInvoice(String invoiceId, Invoice invoice) async {
  await FirebaseFirestore.instance
      .collection('invoices')
      .doc(invoiceId)
      .update(invoice.toFirestore());
}
```

**Editable Fields:**
- Client
- Line items (add/remove/modify)
- Issue date & due date
- Payment terms
- Notes
- Status

---

### 🗑️ DELETE - Remove Invoice
**Screen**: Invoice List / Invoice Details  
**File**: `lib/screens/invoices_list_screen.dart`

**Process:**
1. User clicks "Delete" button or swipes invoice
2. Confirmation dialog appears
3. User confirms deletion
4. Invoice removed from Firestore and local state

**Code Implementation:**
```dart
// InvoiceProvider
Future<void> deleteInvoice(String invoiceId) async {
  await firebaseService.deleteInvoice(invoiceId);
  invoices.removeWhere((inv) => inv.id == invoiceId);
  notifyListeners();
}

// FirebaseService
Future<void> deleteInvoice(String invoiceId) async {
  await FirebaseFirestore.instance
      .collection('invoices')
      .doc(invoiceId)
      .delete();
}
```

**Safety Features:**
- Confirmation dialog required
- Cannot be undone warning
- Soft delete option (future enhancement)

---

## 👥 CLIENT CRUD OPERATIONS

### ✅ CREATE - Add New Client
**Screen**: Manage Clients Screen  
**File**: `lib/screens/manage_clients_screen.dart`

**Process:**
1. User clicks "Add Client" button
2. Fills in client details form
3. Clicks "Save Client"
4. Client saved to Firestore

**Fields:**
- Name (required)
- Email (required, validated)
- Phone (optional)
- Address (optional)
- City (optional)
- Country (optional)
- Tax ID (optional)

**Code Implementation:**
```dart
Future<void> addClient(Client client) async {
  final docRef = await FirebaseFirestore.instance
      .collection('clients')
      .add(client.toFirestore());
  clients.add(client.copyWith(id: docRef.id));
  notifyListeners();
}
```

---

### 📖 READ - View Clients
**Screen**: Manage Clients Screen  
**File**: `lib/screens/manage_clients_screen.dart`

**Features:**
- Display all clients in list
- Search by name or email
- Sort alphabetically
- View client details

**Code Implementation:**
```dart
Future<List<Client>> fetchClients(String userId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('clients')
      .where('userId', isEqualTo: userId)
      .orderBy('name')
      .get();
  
  return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
}
```

---

### ✏️ UPDATE - Edit Client
**Screen**: Edit Client Dialog  
**File**: `lib/screens/manage_clients_screen.dart`

**Process:**
1. User clicks "Edit" on client
2. Dialog/screen opens with pre-filled data
3. User modifies fields
4. Clicks "Update"

**Code Implementation:**
```dart
Future<void> updateClient(String clientId, Client client) async {
  await FirebaseFirestore.instance
      .collection('clients')
      .doc(clientId)
      .update(client.toFirestore());
  
  final index = clients.indexWhere((c) => c.id == clientId);
  if (index != -1) {
    clients[index] = client;
    notifyListeners();
  }
}
```

---

### 🗑️ DELETE - Remove Client
**Screen**: Manage Clients Screen  
**File**: `lib/screens/manage_clients_screen.dart`

**Process:**
1. User clicks "Delete" on client
2. Confirmation dialog appears
3. User confirms deletion
4. Client removed from database

**Validation:**
- Check if client has associated invoices
- Warning if deleting client with invoices

**Code Implementation:**
```dart
Future<void> deleteClient(String clientId) async {
  await FirebaseFirestore.instance
      .collection('clients')
      .doc(clientId)
      .delete();
  
  clients.removeWhere((c) => c.id == clientId);
  notifyListeners();
}
```

---

## 📦 PRODUCT/SERVICE CRUD OPERATIONS

### ✅ CREATE - Add New Product
**Screen**: Manage Products/Services Screen  
**File**: `lib/screens/manageProducts.dart`

**Process:**
1. User clicks "Add Product" button
2. Fills product form (name, description, price)
3. Selects category
4. Clicks "Save Product"

**Fields:**
- Product/Service name (required)
- Description (optional)
- Unit price (required, positive number)
- Category (optional)

**Code Implementation:**
```dart
Future<void> addProduct(Product product) async {
  final docRef = await FirebaseFirestore.instance
      .collection('products')
      .add(product.toFirestore());
  
  products.add(product.copyWith(id: docRef.id));
  notifyListeners();
}
```

---

### 📖 READ - View Products
**Screen**: Manage Products Screen  
**File**: `lib/screens/manageProducts.dart`

**Features:**
- Display all products in list
- Search by product name
- Filter by category
- Sort by name or price

**Code Implementation:**
```dart
Future<List<Product>> fetchProducts(String userId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('userId', isEqualTo: userId)
      .orderBy('name')
      .get();
  
  return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
}
```

---

### ✏️ UPDATE - Edit Product
**Screen**: Edit Product Dialog  
**File**: `lib/screens/manageProducts.dart`

**Process:**
1. User clicks "Edit" on product
2. Form opens with current product data
3. User modifies name, description, or price
4. Clicks "Update"

**Code Implementation:**
```dart
Future<void> updateProduct(String productId, Product product) async {
  await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)
      .update(product.toFirestore());
  
  final index = products.indexWhere((p) => p.id == productId);
  if (index != -1) {
    products[index] = product;
    notifyListeners();
  }
}
```

---

### 🗑️ DELETE - Remove Product
**Screen**: Manage Products Screen  
**File**: `lib/screens/manageProducts.dart`

**Process:**
1. User clicks "Delete" on product
2. Confirmation dialog
3. User confirms
4. Product removed from catalog

**Code Implementation:**
```dart
Future<void> deleteProduct(String productId) async {
  await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)
      .delete();
  
  products.removeWhere((p) => p.id == productId);
  notifyListeners();
}
```

---

## 🔄 STATE MANAGEMENT (Provider Pattern)

### How CRUD Operations Update UI

```dart
// 1. User triggers action
onPressed: () => provider.createInvoice(invoice)

// 2. Provider calls Firebase Service
Future<void> createInvoice(Invoice invoice) async {
  await firebaseService.addInvoice(invoice);
  
  // 3. Update local state
  invoices.add(invoice);
  
  // 4. Notify listeners (rebuilds UI)
  notifyListeners();
}

// 5. UI rebuilds automatically
Consumer<InvoiceProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.invoices.length,
      itemBuilder: (context, index) {
        return InvoiceCard(provider.invoices[index]);
      },
    );
  },
)
```

---

## 🛡️ ERROR HANDLING

### All CRUD Operations Include:

```dart
try {
  // Firestore operation
  await FirebaseFirestore.instance
      .collection('invoices')
      .add(data);
  
  // Success feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invoice created successfully')),
  );
} catch (e) {
  // Error handling
  print('Error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to create invoice: $e')),
  );
}
```

---

## 📊 CRUD OPERATIONS SUMMARY

| Entity | Create | Read | Update | Delete | Search | Filter |
|--------|--------|------|--------|--------|--------|--------|
| **Invoices** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Clients** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Products** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 🔐 SECURITY (Firestore Rules)

All CRUD operations are protected by Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only access their own data
    match /invoices/{invoiceId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    match /clients/{clientId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    match /products/{productId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
  }
}
```

---

## 📱 REAL-TIME SYNC

All CRUD operations sync in real-time:
- **Create**: New item appears instantly on all devices
- **Read**: Snapshot listeners update UI automatically
- **Update**: Changes reflected immediately across devices
- **Delete**: Removal syncs to all connected clients

---

**Last Updated**: December 24, 2025  
**Status**: All CRUD Operations Fully Implemented ✅
