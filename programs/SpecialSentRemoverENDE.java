import java.io.*;

public class SpecialSentRemoverENDE {

    public static boolean isNumber(String word) {
        try {
            Double.parseDouble(word);
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    public static boolean isCommonWord(String word) {
        for (int i = 0; i < word.length(); ++i) {
            char c;
            if (i == 0) {
                c = word.toLowerCase().charAt(0);
            } else {
                c = word.charAt(i);
            }
            if (c <= 'z' && c >= 'a') {
                continue;
            } else {
                return false;
            }
        }
        return true;
    }

    public static boolean isCapital(String word) {
        for (int i = 0; i < word.length(); ++i) {
            if (word.charAt(i) >= 'A' && word.charAt(i) <= 'Z') {
                continue;
            } else {
                return false;
            }
        }
        return true;
    }

    public static boolean isAlmostNumberCap(String sentence) {
        String[] tokens = sentence.trim().split(" ");
        int cnt = 0;
        for (String word : tokens) {
            if (isNumber(word) || isCapital(word)) ++cnt;
        }
        if ((double) cnt / (double) tokens.length >= 0.5) {
            return true;
        }
        return false;
    }

    public static boolean isUglySentence(String sentence) {
        String[] tokens = sentence.trim().split(" ");
        int cnt = 0;
        for (String word : tokens) {
            if (!isCommonWord(word)) ++cnt;
        }
        if ((double) cnt / (double) tokens.length >=0.5) {
            return true;
        }
        return false;
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 5) {
            System.out.println("Usage: java SpecialSentRemoverENDE en de en_output de_output removed_to_file");
            return;
        }
        String enFile = args[0];
        String deFile = args[1];
        String enOutputFile = args[2];
        String deOutputFile = args[3];
        String removedOutputFile = args[4];

        BufferedReader brEn = new BufferedReader(new InputStreamReader(new FileInputStream(enFile), "utf-8"));
        BufferedReader brDe = new BufferedReader(new InputStreamReader(new FileInputStream(deFile), "utf-8"));
        BufferedWriter bwEn = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(enOutputFile), "utf-8"));
        BufferedWriter bwDe = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(deOutputFile), "utf-8"));
        BufferedWriter bwRem = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(removedOutputFile), "utf-8"));

        String en, de;

        while ((en = brEn.readLine()) != null) {
            de = brDe.readLine();
            if (isUglySentence(en) || isAlmostNumberCap(de)) {
                bwRem.write(en + " ||| " + de + "\n");
            } else {
                bwEn.write(en + "\n");
                bwDe.write(de + "\n");
            }
        }

        brEn.close();
        brDe.close();
        bwEn.close();
        bwDe.close();
        bwRem.close();
    }
}
