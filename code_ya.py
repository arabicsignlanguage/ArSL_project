import os
import shutil

# 1. المسار الرئيسي لقاعدة البيانات في جهازك
base_dir = r"D:\Github\datasets"

# 2. المجلدات التي سنبحث فيها (كما ذكرتي أنها تحتوي على train و valid)
splits = ['train', 'valid']

# 3. مسار المجلد الجديد الذي سنحفظ فيه كل صور حرف الياء المستخرجة
output_dir = r"D:\Github\extracted_ya"
output_images = os.path.join(output_dir, "images")
output_labels = os.path.join(output_dir, "labels")

# إنشاء المجلدات الجديدة لتجميع الصور
os.makedirs(output_images, exist_ok=True)
os.makedirs(output_labels, exist_ok=True)

# 4. رقم الكلاس لحرف 'ya' بناءً على ملف yaml هو 29
target_class = '29'

# دالة مخصصة للبحث والنسخ
def extract_ya_images(split_name):
    labels_dir = os.path.join(base_dir, split_name, 'labels')
    images_dir = os.path.join(base_dir, split_name, 'images')
    
    # التأكد من أن المجلدات موجودة لتجنب أي أخطاء
    if not os.path.exists(labels_dir) or not os.path.exists(images_dir):
        print(f"تنبيه: مجلد {split_name} غير موجود أو مساره غير صحيح.")
        return

    # المرور على جميع ملفات التسميات
    for label_file in os.listdir(labels_dir):
        if label_file.endswith('.txt'):
            label_path = os.path.join(labels_dir, label_file)
            
            with open(label_path, 'r', encoding='utf-8') as file:
                lines = file.readlines()
                
            # التحقق مما إذا كان حرف الياء (رقم 29) موجوداً في هذا الملف
            has_target_class = False
            for line in lines:
                class_id = line.strip().split()[0]
                if class_id == target_class:
                    has_target_class = True
                    break
                    
            # إذا وجدنا الحرف، ننسخ ملف الـ txt والصورة المقابلة له
            if has_target_class:
                # نسخ ملف التسمية
                shutil.copy(label_path, os.path.join(output_labels, label_file))
                
                # البحث عن الصورة المقابلة (سواء كانت jpg أو png أو jpeg)
                image_base_name = label_file.replace('.txt', '')
                for ext in ['.jpg', '.png', '.jpeg']:
                    image_path = os.path.join(images_dir, image_base_name + ext)
                    if os.path.exists(image_path):
                        shutil.copy(image_path, os.path.join(output_images, image_base_name + ext))
                        break

# تطبيق الدالة على مجلدي train و valid
print("بدأ استخراج الصور...")
for split in splits:
    extract_ya_images(split)
    
print(f"تم الانتهاء بنجاح! جميع صور حرف الياء موجودة الآن في: {output_dir}")