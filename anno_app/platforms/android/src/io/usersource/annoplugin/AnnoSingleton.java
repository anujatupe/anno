package io.usersource.annoplugin;

import java.io.IOException;
import java.io.InputStream;
import java.util.Random;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import io.usersource.anno.CommunityActivity;
import io.usersource.annoplugin.utils.AnnoUtils;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

public class AnnoSingleton {
	private static AnnoSingleton instance = null;

	String ANONYMOUS_USER_EMAIL = "dev%s@devnull.usersource.io";
	String ANONYMOUS_USER_DISPLAY_NAME = "Anonymous";

	String serverConfigFilePath = "www/anno/scripts/server-url.json";
	String pluginConfigFilePath = "www/anno/scripts/plugin_settings/pluginConfig.json";

	String email, displayName, userImageURL, teamKey, teamSecret;
	JSONObject serverConfig, pluginConfig;
	String cloudHost;

	Class<?> customInfoActivity = null;
	static Context appContext = null;

	protected AnnoSingleton() {
		// Exists only to defeat instantiation.
	}

	public static AnnoSingleton getInstance(Context context) {
		if (instance == null) {
			instance = new AnnoSingleton();
			if ((appContext == null) && (context != null)) {
				appContext = context.getApplicationContext();
			}
		}
		return instance;
	}

	public void setupWithUserInfo(String emailValue, String displayNameValue,
			String userImageURLValue, String teamKeyValue,
			String teamSecretValue) {
		this.email = emailValue;
		this.displayName = displayNameValue;
		this.userImageURL = userImageURLValue;
		this.teamKey = teamKeyValue;
		this.teamSecret = teamSecretValue;
	}

	public void setupAnonymousUserWithTeamCredentials(String teamKeyValue, String teamSecretValue) {
		String secs = String.format("%d", System.currentTimeMillis() / 1000);
		String randomNum = String.format("%d", (new Random()).nextInt(100) + 0);
		String additionalString = String.format("%s%s", secs, randomNum);
		String emailValue = String.format(ANONYMOUS_USER_EMAIL, additionalString);
		String displayNameValue = ANONYMOUS_USER_DISPLAY_NAME;
		this.setupWithUserInfo(emailValue, displayNameValue, "", teamKeyValue, teamSecretValue);
	}

	public void setCustomInfoActivity(Class<?> customInfo) {
		this.customInfoActivity = customInfo;
	}

	public void showCommunityPage(Activity activity) {
		Intent intent = new Intent(activity, CommunityActivity.class);
		activity.startActivity(intent);
	}

	public void showAnnoDrawPage(Activity activity, String imageURI) {
		String packageName = activity.getPackageName();
		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setClassName(packageName, "io.usersource.anno.AnnoDrawActivity");
		intent.setType("image/*");
		Uri imageUri = Uri.parse(imageURI);
		intent.putExtra(Intent.EXTRA_STREAM, imageUri);
		intent.putExtra(AnnoUtils.LEVEL, 0);
		activity.startActivity(intent);
	}

	public JSONArray getUserInfo() {
		JSONArray returnData = new JSONArray();
		returnData.put(this.email);
		returnData.put(this.displayName);
		returnData.put(this.userImageURL);
		returnData.put(this.teamKey);
		returnData.put(this.teamSecret);
		return returnData;
	}

	private JSONObject readJSONFromFile(String filePath) throws JSONException {
		String json = null;
		JSONObject jsonData;

		try {
			InputStream is = appContext.getAssets().open(filePath);
		    int size = is.available();
		    byte[] buffer = new byte[size];
		    is.read(buffer);
		    is.close();
		    json = new String(buffer, "UTF-8");
		    jsonData = new JSONObject(json);
		} catch (IOException ex) {
		    ex.printStackTrace();
		    return null;
		}

		return jsonData;
	}

	public void readServerConfiguration() {
		try {
			serverConfig = readJSONFromFile(serverConfigFilePath);
			cloudHost = serverConfig.getJSONObject("1").getString("apiRoot");
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	public void readPluginConfiguration() {
		try {
			pluginConfig = readJSONFromFile(pluginConfigFilePath);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}
}