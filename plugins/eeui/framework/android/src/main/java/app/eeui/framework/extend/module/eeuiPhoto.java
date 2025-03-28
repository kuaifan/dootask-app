package app.eeui.framework.extend.module;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.provider.MediaStore;
import android.util.Base64;

import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.bridge.JSCallback;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import app.eeui.framework.extend.module.utilcode.constant.PermissionConstants;
import app.eeui.framework.extend.module.utilcode.util.PermissionUtils;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

public class eeuiPhoto {

    /**
     * 上传图片到指定URL
     * 该方法将图片文件以multipart/form-data格式上传到指定URL
     *
     * @param object 包含以下参数的JSON字符串：
     *              - url: (必需) 上传的目标URL地址
     *              - path: (必需) 图片文件的本地路径
     *              - fieldName: (可选) 表单字段名，默认为"file"
     *              - data: (可选) 附加表单数据，必须是字典类型，键值会被转换为表单字段
     *              - headers: (可选) 自定义HTTP请求头，必须是字典类型
     * @param callback 回调函数，会返回上传结果，包含以下信息：
     *                - 成功: {status: "success", statusCode: HTTP状态码, data: 服务器响应数据}
     *                - 失败: {status: "error", error: 错误信息}
     */
    public static void uploadPhoto(Context context, String object, JSCallback callback) {
        try {
            JSONObject json = JSONObject.parseObject(object);
            if (json == null) {
                if (callback != null) {
                    final JSONObject errorResult = createErrorJSON("参数格式错误");
                    ((Activity) context).runOnUiThread(() -> {
                        callback.invoke(errorResult);
                    });
                }
                return;
            }

            if (!json.containsKey("url") || !json.containsKey("path")) {
                if (callback != null) {
                    final JSONObject errorResult = createErrorJSON("必须包含url和path参数");
                    ((Activity) context).runOnUiThread(() -> {
                        callback.invoke(errorResult);
                    });
                }
                return;
            }

            String url = json.getString("url");
            String path = json.getString("path");
            String fieldName = json.containsKey("fieldName") ? json.getString("fieldName") : "file";

            // 获取附加数据
            Map<String, Object> dataMap = new HashMap<>();
            if (json.containsKey("data") && json.get("data") instanceof JSONObject) {
                dataMap = ((JSONObject) json.get("data")).getInnerMap();
            }

            // 获取请求头
            Map<String, String> headersMap = new HashMap<>();
            if (json.containsKey("headers") && json.get("headers") instanceof JSONObject) {
                JSONObject headers = (JSONObject) json.get("headers");
                for (String key : headers.keySet()) {
                    headersMap.put(key, headers.getString(key));
                }
            }

            // 创建File对象
            File file = new File(path);
            if (!file.exists()) {
                if (callback != null) {
                    final JSONObject errorResult = createErrorJSON("文件不存在");
                    ((Activity) context).runOnUiThread(() -> {
                        callback.invoke(errorResult);
                    });
                }
                return;
            }

            // 创建OkHttpClient
            OkHttpClient client = new OkHttpClient.Builder()
                .connectTimeout(60, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .writeTimeout(60, TimeUnit.SECONDS)
                .build();

            // 创建RequestBody
            MultipartBody.Builder requestBuilder = new MultipartBody.Builder().setType(MultipartBody.FORM);

            // 添加文件
            RequestBody fileBody = RequestBody.create(MediaType.parse("application/octet-stream"), file);
            requestBuilder.addFormDataPart(fieldName, file.getName(), fileBody);

            // 添加附加数据
            for (Map.Entry<String, Object> entry : dataMap.entrySet()) {
                String key = entry.getKey();
                Object value = entry.getValue();
                requestBuilder.addFormDataPart(key, String.valueOf(value));
            }

            // 构建请求体
            RequestBody requestBody = requestBuilder.build();

            // 创建请求
            Request.Builder builder = new Request.Builder()
                .url(url)
                .post(requestBody);

            // 添加请求头
            for (Map.Entry<String, String> entry : headersMap.entrySet()) {
                builder.addHeader(entry.getKey(), entry.getValue());
            }

            Request request = builder.build();

            // 执行请求
            client.newCall(request).enqueue(new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    if (callback != null) {
                        final JSONObject errorResult = createErrorJSON(e.getMessage());
                        ((Activity) context).runOnUiThread(() -> {
                            callback.invoke(errorResult);
                        });
                    }
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    int statusCode = response.code();
                    String responseBody = response.body().string();

                    if (callback != null) {
                        final JSONObject result = new JSONObject();
                        result.put("status", "success");
                        result.put("statusCode", statusCode);
                        result.put("data", responseBody);
                        ((Activity) context).runOnUiThread(() -> {
                            callback.invoke(result);
                        });
                    }
                }
            });
        } catch (Exception e) {
            if (callback != null) {
                final JSONObject errorResult = createErrorJSON("处理图片时出错: " + e.getMessage());
                ((Activity) context).runOnUiThread(() -> {
                    callback.invoke(errorResult);
                });
            }
        }
    }

    /**
     * 计算图片的采样大小，用于降低内存占用
     */
    private static int calculateInSampleSize(int width, int height, int reqWidth, int reqHeight) {
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    /**
     * 获取相册最新图片
     * 同时返回缩略图和原图的路径及相关信息
     *
     * @param context 上下文环境
     * @param callback 完成回调，返回包含以下信息的字典：
     *                   - status: 状态码，"success"表示成功，"error"表示失败
     *                   - error: 如果失败，包含错误信息
     *                   - created: 照片创建时间戳（秒）
     *                   - thumbnail: 缩略图信息，包含path、base64、width、height、size
     *                   - original: 原图信息，包含path、width、height、size
     */
    public static void getLatestPhoto(Context context, JSCallback callback) {
        try {
            // 检查存储权限
            if (PermissionUtils.isGranted(Manifest.permission.READ_EXTERNAL_STORAGE)) {
                getLatestPhotoInternal(context, callback);
            } else {
                // 请求权限
                PermissionUtils.permission(PermissionConstants.STORAGE)
                    .callback(new PermissionUtils.SimpleCallback() {
                        @Override
                        public void onGranted() {
                            getLatestPhotoInternal(context, callback);
                        }

                        @Override
                        public void onDenied() {
                            if (callback != null) {
                                final JSONObject errorResult = createErrorJSON("没有存储访问权限");
                                ((Activity) context).runOnUiThread(() -> {
                                    callback.invoke(errorResult);
                                });
                            }
                        }
                    }).request();
            }
        } catch (Exception e) {
            if (callback != null) {
                final JSONObject errorResult = createErrorJSON("获取照片时出错: " + e.getMessage());
                ((Activity) context).runOnUiThread(() -> {
                    callback.invoke(errorResult);
                });
            }
        }
    }

    /**
     * 获取最新照片的内部实现
     */
    private static void getLatestPhotoInternal(Context context, JSCallback callback) {
        new Thread(() -> {
            try {
                // 查询最新的图片
                String[] projection = {
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.DATA,
                    MediaStore.Images.Media.DATE_ADDED,
                    MediaStore.Images.Media.WIDTH,
                    MediaStore.Images.Media.HEIGHT,
                    MediaStore.Images.Media.SIZE
                };
                String sortOrder = MediaStore.Images.Media.DATE_ADDED + " DESC";

                ContentResolver contentResolver = context.getContentResolver();
                Cursor cursor = contentResolver.query(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    null,
                    null,
                    sortOrder
                );

                if (cursor == null || !cursor.moveToFirst()) {
                    if (cursor != null) {
                        cursor.close();
                    }
                    if (callback != null) {
                        final JSONObject errorResult = createErrorJSON("未找到照片");
                        ((Activity) context).runOnUiThread(() -> {
                            callback.invoke(errorResult);
                        });
                    }
                    return;
                }

                // 获取图片信息
                int idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
                int pathColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                int dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED);
                int widthColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH);
                int heightColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT);
                int sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE);

                long id = cursor.getLong(idColumn);
                String path = cursor.getString(pathColumn);
                long dateAdded = cursor.getLong(dateColumn);
                int width = cursor.getInt(widthColumn);
                int height = cursor.getInt(heightColumn);
                long size = cursor.getLong(sizeColumn);

                cursor.close();

                File originalFile = new File(path);
                if (!originalFile.exists()) {
                    if (callback != null) {
                        final JSONObject errorResult = createErrorJSON("文件不存在");
                        ((Activity) context).runOnUiThread(() -> {
                            callback.invoke(errorResult);
                        });
                    }
                    return;
                }

                // 准备结果对象
                JSONObject result = new JSONObject();
                result.put("status", "success");
                result.put("created", dateAdded);

                // 获取原图信息
                JSONObject originalInfo = new JSONObject();
                originalInfo.put("path", path);
                originalInfo.put("width", width);
                originalInfo.put("height", height);
                originalInfo.put("size", size);
                result.put("original", originalInfo);

                // 生成缩略图并获取信息
                JSONObject thumbnailInfo = createThumbnail(context, path);
                if (thumbnailInfo != null) {
                    result.put("thumbnail", thumbnailInfo);
                }

                // 确保在主线程中回调
                if (callback != null) {
                    final JSONObject finalResult = result;
                    ((Activity) context).runOnUiThread(() -> {
                        callback.invoke(finalResult);
                    });
                }

            } catch (Exception e) {
                if (callback != null) {
                    final JSONObject errorResult = createErrorJSON("处理图片时出错: " + e.getMessage());
                    ((Activity) context).runOnUiThread(() -> {
                        callback.invoke(errorResult);
                    });
                }
            }
        }).start();
    }

    /**
     * 为指定路径的图片创建缩略图并返回相关信息
     */
    private static JSONObject createThumbnail(Context context, String path) {
        try {
            // 创建File对象
            File originalFile = new File(path);
            if (!originalFile.exists()) {
                return null;
            }

            // 加载原始位图
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(path, options);

            int originalWidth = options.outWidth;
            int originalHeight = options.outHeight;

            if (originalWidth <= 0 || originalHeight <= 0) {
                return null;
            }

            // 计算长宽比
            float aspectRatio = (float) originalWidth / originalHeight;

            // 设置目标尺寸，确保最小边为300像素
            int minSize = 300;
            int targetWidth, targetHeight;
            boolean needCrop = false;

            // 判断是否为极端长宽比（超过5:1或1:5）
            if (aspectRatio >= 5.0f || aspectRatio <= 0.2f) {
                // 对于超长或超宽的图片，保持1:1到5:1之间的比例，并截取中间部分
                needCrop = true;

                if (aspectRatio >= 5.0f) {
                    // 非常宽的图片
                    targetWidth = minSize * 5;
                    targetHeight = minSize;
                } else {
                    // 非常高的图片
                    targetWidth = minSize;
                    targetHeight = minSize * 5;
                }
            } else {
                // 普通长宽比，保持原始比例
                if (aspectRatio >= 1.0f) {
                    // 横向图片或正方形
                    targetWidth = (int) (minSize * aspectRatio);
                    targetHeight = minSize;
                } else {
                    // 纵向图片
                    targetWidth = minSize;
                    targetHeight = (int) (minSize / aspectRatio);
                }
            }

            // 计算采样率
            options.inJustDecodeBounds = false;
            options.inSampleSize = calculateInSampleSize(originalWidth, originalHeight, targetWidth, targetHeight);

            // 加载压缩后的位图
            Bitmap originalBitmap = BitmapFactory.decodeFile(path, options);
            if (originalBitmap == null) {
                return null;
            }

            Bitmap resultBitmap;

            if (needCrop) {
                // 需要裁剪中间部分
                int x = 0, y = 0;

                if (aspectRatio >= 5.0f) {
                    // 超宽图片，取中间部分
                    x = (originalBitmap.getWidth() - targetWidth * originalBitmap.getHeight() / targetHeight) / 2;
                    resultBitmap = Bitmap.createBitmap(originalBitmap, x, 0,
                        originalBitmap.getWidth() - 2 * x, originalBitmap.getHeight());
                } else {
                    // 超高图片，取中间部分
                    y = (originalBitmap.getHeight() - targetHeight * originalBitmap.getWidth() / targetWidth) / 2;
                    resultBitmap = Bitmap.createBitmap(originalBitmap, 0, y,
                        originalBitmap.getWidth(), originalBitmap.getHeight() - 2 * y);
                }
            } else {
                // 不需要裁剪，只调整大小
                resultBitmap = Bitmap.createScaledBitmap(originalBitmap, targetWidth, targetHeight, true);
            }

            if (resultBitmap == null) {
                if (originalBitmap != null) {
                    originalBitmap.recycle();
                }
                return null;
            }

            // 保存处理后的图片到临时文件
            File cacheDir = new File(context.getCacheDir(), "thumbs");
            if (!cacheDir.exists()) {
                cacheDir.mkdirs();
            }

            String fileName = "thumb_" + System.currentTimeMillis() + ".jpg";
            File outputFile = new File(cacheDir, fileName);
            String outputPath = outputFile.getAbsolutePath();

            FileOutputStream fos = null;
            try {
                fos = new FileOutputStream(outputFile);
                resultBitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
                fos.flush();
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            } finally {
                if (fos != null) {
                    try {
                        fos.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }

            // 获取Base64编码
            String base64;
            try {
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                resultBitmap.compress(Bitmap.CompressFormat.JPEG, 90, baos);
                byte[] imageBytes = baos.toByteArray();
                base64 = "data:image/jpeg;base64," + Base64.encodeToString(imageBytes, Base64.NO_WRAP);
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }

            // 释放资源
            if (resultBitmap != originalBitmap) {
                originalBitmap.recycle();
            }
            resultBitmap.recycle();

            // 返回缩略图信息
            JSONObject thumbnailInfo = new JSONObject();
            thumbnailInfo.put("path", outputPath);
            thumbnailInfo.put("base64", base64);
            thumbnailInfo.put("width", targetWidth);
            thumbnailInfo.put("height", targetHeight);
            thumbnailInfo.put("size", outputFile.length());

            return thumbnailInfo;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 创建错误响应JSON对象
     */
    private static JSONObject createErrorJSON(String message) {
        JSONObject result = new JSONObject();
        result.put("status", "error");
        result.put("error", message);
        return result;
    }
}
