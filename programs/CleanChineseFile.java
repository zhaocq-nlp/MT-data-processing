import java.io.*;


public class CleanChineseFile {
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.out.println("Usage: java SplitChineseFile in out");
            return;
        }
        String inFile = args[0];
        String outFile = args[1];


        BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(inFile), "utf-8"));
        BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outFile), "utf-8"));
        String line;
        while ((line = br.readLine()) != null) {
            String[] tokens = line.trim().split(" +");
            StringBuffer sb = new StringBuffer();
            for(String tok: tokens){
                sb.append(tok +" ");
            }

            bw.write(sb.toString().trim() + "\n");
        }
        br.close();
        bw.close();


    }
}
