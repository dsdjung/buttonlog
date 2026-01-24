package com.buttonlog.app.di

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import com.buttonlog.app.BuildConfig
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiConfig
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Named
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    private const val PREFS_NAME = "buttonlog_prefs"
    private const val KEY_AUTH_TOKEN = "auth_token"

    @Provides
    @Singleton
    fun provideSharedPreferences(@ApplicationContext context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            .create()
    }

    @SuppressLint("HardwareIds")
    @Provides
    @Singleton
    @Named("deviceId")
    fun provideDeviceId(@ApplicationContext context: Context): String {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(
        sharedPreferences: SharedPreferences,
        @Named("deviceId") deviceId: String
    ): Interceptor {
        return Interceptor { chain ->
            val original = chain.request()
            val token = sharedPreferences.getString(KEY_AUTH_TOKEN, null)

            val requestBuilder = original.newBuilder()
                .header(ApiConfig.HEADER_CONTENT_TYPE, ApiConfig.CONTENT_TYPE_JSON)
                .header(ApiConfig.HEADER_ACCEPT, ApiConfig.CONTENT_TYPE_JSON)
                // Client version tracking headers
                .header(ApiConfig.HEADER_APP_VERSION, BuildConfig.VERSION_NAME)
                .header(ApiConfig.HEADER_PLATFORM, "android")
                .header(ApiConfig.HEADER_DEVICE_ID, deviceId)

            if (!token.isNullOrEmpty()) {
                requestBuilder.header(ApiConfig.HEADER_AUTHORIZATION, "Bearer $token")
            }

            chain.proceed(requestBuilder.build())
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(authInterceptor: Interceptor): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(ApiConfig.TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(ApiConfig.TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(ApiConfig.TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, gson: Gson): Retrofit {
        return Retrofit.Builder()
            .baseUrl(ApiConfig.BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    @Provides
    @Singleton
    fun provideAPIService(retrofit: Retrofit): APIService {
        return retrofit.create(APIService::class.java)
    }
}
