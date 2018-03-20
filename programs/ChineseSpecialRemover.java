import java.io.*;

public class ChineseSpecialRemover {

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

    public static boolean isNumber(String word) {
        try {
            Double.parseDouble(word);
        } catch (Exception e) {
            return false;
        }
        return true;
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

    public static boolean isAlmostAscii(String sentence) {
        String[] tokens = sentence.trim().split(" ");
        int cnt = 0;
        for (String word : tokens) {
            if (isNumber(word) || isCommonWord(word)) ++cnt;
        }
        if ((double) cnt / (double) tokens.length >= 0.4) {
            return true;
        }
        return false;
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 8) {
            System.out.println("Usage: java LenRatioRemover zh zh_char en zhchar_div_en_max zhchar_div_en_min zh_output en_output removed_to_file");
            return;
        }
        String srcFile = args[0];
        String srcCharFile = args[1];
        String trgFile = args[2];
        double maxRatio = Double.parseDouble(args[3]);
        double minRatio = Double.parseDouble(args[4]);
        String srcOutputFile = args[5];
        String trgOutputFile = args[6];
        String removedOutputFile = args[7];

        BufferedReader brSrc = new BufferedReader(new InputStreamReader(new FileInputStream(srcFile), "utf-8"));
        BufferedReader brSrcChar = new BufferedReader(new InputStreamReader(new FileInputStream(srcCharFile), "utf-8"));
        BufferedReader brTrg = new BufferedReader(new InputStreamReader(new FileInputStream(trgFile), "utf-8"));
        BufferedWriter bwSrc = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(srcOutputFile), "utf-8"));
        BufferedWriter bwTrg = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(trgOutputFile), "utf-8"));
        BufferedWriter bwRem = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(removedOutputFile), "utf-8"));

        String zh, zhChar, en;

        while ((zh = brSrc.readLine()) != null) {
            zhChar = brSrcChar.readLine();
            en = brTrg.readLine();
            double val = (double) zhChar.trim().split(" ").length / (double) en.trim().split(" ").length;
            if (val <= minRatio || val >= maxRatio) {
                bwRem.write("len" + " ||| " + zh + " ||| " + en + "\n");
            } else {
                if(isUglySentence(en) || isAlmostAscii(zh)){
                    bwRem.write("ascii" + " ||| " + zh + " ||| " + en + "\n");
                }else {
                    bwSrc.write(zh + "\n");
                    bwTrg.write(en + "\n");
                }
            }
        }


        brSrc.close();
        brSrcChar.close();
        brTrg.close();
        bwSrc.close();
        bwTrg.close();
        bwRem.close();
    }
}
