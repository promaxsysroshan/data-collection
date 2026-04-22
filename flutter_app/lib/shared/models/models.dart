class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final double walletBalance;
  final bool isActive;
  final String createdAt;
  final String? profileImageUrl;
  final int? age;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? aadharNumber;
  final String? panNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankBranch;
  final String? upiId;

  UserModel({
    required this.id, required this.email, required this.fullName,
    required this.role, required this.walletBalance, required this.isActive,
    required this.createdAt, this.profileImageUrl, this.age, this.dateOfBirth,
    this.gender, this.phone, this.address, this.city, this.state,
    this.pincode, this.aadharNumber, this.panNumber, this.bankName,
    this.bankAccountNumber, this.bankIfsc, this.bankBranch, this.upiId,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id']?.toString() ?? '',
    email: j['email']?.toString() ?? '',
    fullName: j['full_name']?.toString() ?? '',
    role: j['role']?.toString() ?? '',
    walletBalance: double.tryParse(j['wallet_balance']?.toString() ?? '0') ?? 0,
    isActive: j['is_active'] as bool? ?? true,
    createdAt: j['created_at']?.toString() ?? '',
    profileImageUrl: j['profile_image_url']?.toString(),
    age: j['age'] as int?,
    dateOfBirth: j['date_of_birth']?.toString(),
    gender: j['gender']?.toString(),
    phone: j['phone']?.toString(),
    address: j['address']?.toString(),
    city: j['city']?.toString(),
    state: j['state']?.toString(),
    pincode: j['pincode']?.toString(),
    aadharNumber: j['aadhar_number']?.toString(),
    panNumber: j['pan_number']?.toString(),
    bankName: j['bank_name']?.toString(),
    bankAccountNumber: j['bank_account_number']?.toString(),
    bankIfsc: j['bank_ifsc']?.toString(),
    bankBranch: j['bank_branch']?.toString(),
    upiId: j['upi_id']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'full_name': fullName, 'role': role,
    'wallet_balance': walletBalance, 'is_active': isActive,
    'created_at': createdAt, 'profile_image_url': profileImageUrl,
    'age': age, 'date_of_birth': dateOfBirth, 'gender': gender,
    'phone': phone, 'address': address, 'city': city, 'state': state,
    'pincode': pincode, 'aadhar_number': aadharNumber, 'pan_number': panNumber,
    'bank_name': bankName, 'bank_account_number': bankAccountNumber,
    'bank_ifsc': bankIfsc, 'bank_branch': bankBranch, 'upi_id': upiId,
  };

  bool get isAdmin  => role == 'admin';
  bool get isLevel1 => role == 'level1';

  UserModel copyWith({double? walletBalance, String? profileImageUrl, String? fullName}) => UserModel(
    id: id, email: email, fullName: fullName ?? this.fullName, role: role,
    walletBalance: walletBalance ?? this.walletBalance, isActive: isActive,
    createdAt: createdAt, profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    age: age, dateOfBirth: dateOfBirth, gender: gender, phone: phone,
    address: address, city: city, state: state, pincode: pincode,
    aadharNumber: aadharNumber, panNumber: panNumber, bankName: bankName,
    bankAccountNumber: bankAccountNumber, bankIfsc: bankIfsc, bankBranch: bankBranch,
    upiId: upiId,
  );
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String? instructions;
  final String status;
  final String priority;
  final String? dueDate;
  final double paymentAmount;
  final String createdAt;
  final String? assignedToId;
  final String createdById;
  final String? assigneeName;
  final String? creatorName;
  final int submissionCount;

  TaskModel({
    required this.id, required this.title, this.description, this.instructions,
    required this.status, required this.priority, this.dueDate,
    required this.paymentAmount, required this.createdAt,
    this.assignedToId, required this.createdById, this.assigneeName,
    this.creatorName, this.submissionCount = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    instructions: j['instructions']?.toString(),
    status: j['status']?.toString() ?? 'pending',
    priority: j['priority']?.toString() ?? 'medium',
    dueDate: j['due_date']?.toString(),
    paymentAmount: double.tryParse(j['payment_amount']?.toString() ?? '0') ?? 0,
    createdAt: j['created_at']?.toString() ?? '',
    assignedToId: j['assigned_to_id']?.toString(),
    createdById: j['created_by_id']?.toString() ?? '',
    assigneeName: j['assignee_name']?.toString(),
    creatorName: j['creator_name']?.toString(),
    submissionCount: j['submission_count'] as int? ?? 0,
  );
}

// FIX: Added fileUrl field for file download/reference
class SubmissionFileModel {
  final String id;
  final String filename;
  final String originalFilename;
  final int fileSize;
  final String? mimeType;
  final String createdAt;
  final String? fileUrl; // ← NEW: server relative URL

  SubmissionFileModel({
    required this.id, required this.filename, required this.originalFilename,
    required this.fileSize, this.mimeType, required this.createdAt, this.fileUrl,
  });

  factory SubmissionFileModel.fromJson(Map<String, dynamic> j) => SubmissionFileModel(
    id: j['id']?.toString() ?? '',
    filename: j['filename']?.toString() ?? '',
    originalFilename: j['original_filename']?.toString() ?? '',
    fileSize: j['file_size'] as int? ?? 0,
    mimeType: j['mime_type']?.toString(),
    createdAt: j['created_at']?.toString() ?? '',
    fileUrl: j['file_url']?.toString(),
  );
}

// FIX: Added updatedAt + userEmail fields
class SubmissionModel {
  final String id;
  final String taskId;
  final String userId;
  final String status;
  final String? notes;
  final String? adminRemarks;
  final String createdAt;
  final String updatedAt;    // ← FIXED: was missing
  final String? taskTitle;
  final String? userName;
  final String? userEmail;   // ← NEW
  final List<SubmissionFileModel> files;

  SubmissionModel({
    required this.id, required this.taskId, required this.userId,
    required this.status, this.notes, this.adminRemarks,
    required this.createdAt, required this.updatedAt,
    this.taskTitle, this.userName, this.userEmail, this.files = const [],
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> j) => SubmissionModel(
    id: j['id']?.toString() ?? '',
    taskId: j['task_id']?.toString() ?? '',
    userId: j['user_id']?.toString() ?? '',
    status: j['status']?.toString() ?? 'pending',
    notes: j['notes']?.toString(),
    adminRemarks: j['admin_remarks']?.toString(),
    createdAt: j['created_at']?.toString() ?? '',
    updatedAt: j['updated_at']?.toString() ?? j['created_at']?.toString() ?? '',
    taskTitle: j['task_title']?.toString(),
    userName: j['user_name']?.toString(),
    userEmail: j['user_email']?.toString(),
    files: (j['files'] as List<dynamic>? ?? [])
        .map((f) => SubmissionFileModel.fromJson(f as Map<String, dynamic>))
        .toList(),
  );
}

class WalletTxnModel {
  final String id;
  final double amount;
  final String transactionType;
  final String? description;
  final double balanceAfter;
  final String createdAt;

  WalletTxnModel({
    required this.id, required this.amount, required this.transactionType,
    this.description, required this.balanceAfter, required this.createdAt,
  });

  factory WalletTxnModel.fromJson(Map<String, dynamic> j) => WalletTxnModel(
    id: j['id']?.toString() ?? '',
    amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
    transactionType: j['transaction_type']?.toString() ?? 'credit',
    description: j['description']?.toString(),
    balanceAfter: double.tryParse(j['balance_after']?.toString() ?? '0') ?? 0,
    createdAt: j['created_at']?.toString() ?? '',
  );
}
