import java.io.*;

public class SplitChineseFile {
    public static void main(String[] args) throws Exception {
        if (args.length < 3) {
            System.out.println("Usage: java SplitChineseFile mergedfile src trg");
            return;
        }
        String mergedFile = args[0];
        String srcFile = args[1];
        String trgFile = args[2];


        BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(mergedFile), "utf-8"));
        BufferedWriter bwSrc = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(srcFile), "utf-8"));
        BufferedWriter bwTrg = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(trgFile), "utf-8"));
        String line;
        while ((line = br.readLine()) != null) {
            String[] tokens = line.trim().split("\t");
            bwSrc.write(tokens[0].trim() + "\n");
            bwTrg.write(tokens[1].trim() + "\n");
        }

        br.close();
        bwSrc.close();
        bwTrg.close();


    }
}
