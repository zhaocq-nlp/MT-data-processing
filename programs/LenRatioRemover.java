import java.io.*;

public class LenRatioRemover {

    public static void main(String[] args) throws Exception {
        if (args.length < 7) {
            System.out.println("Usage: java LenRatioRemover src trg src_div_trg_max src_div_trg_min src_output trg_output removed_to_file");
            return;
        }
        String srcFile = args[0];
        String trgFile = args[1];
        double maxRatio = Double.parseDouble(args[2]);
        double minRatio = Double.parseDouble(args[3]);
        String srcOutputFile = args[4];
        String trgOutputFile = args[5];
        String removedOutputFile = args[6];

        BufferedReader brSrc = new BufferedReader(new InputStreamReader(new FileInputStream(srcFile), "utf-8"));
        BufferedReader brTrg = new BufferedReader(new InputStreamReader(new FileInputStream(trgFile), "utf-8"));
        BufferedWriter bwSrc = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(srcOutputFile), "utf-8"));
        BufferedWriter bwTrg = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(trgOutputFile), "utf-8"));
        BufferedWriter bwRem = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(removedOutputFile), "utf-8"));

        String src, trg;

        while ((src = brSrc.readLine()) != null) {
            trg = brTrg.readLine();
            double val = (double) src.trim().split(" ").length / (double) trg.trim().split(" ").length;
            if (val < minRatio || val > maxRatio) {
                bwRem.write(src + " ||| " + trg + "\n");
            } else {
                bwSrc.write(src + "\n");
                bwTrg.write(trg + "\n");
            }
        }


        brSrc.close();
        brTrg.close();
        bwSrc.close();
        bwTrg.close();
        bwRem.close();
    }
}

